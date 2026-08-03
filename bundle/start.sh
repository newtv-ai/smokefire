#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"

env_value() {
  key="$1"
  value=$(grep -E "^${key}=" .env | tail -n 1 | cut -d= -f2- || true)
  printf '%s' "$value"
}

import_offline_images() {
  archive="./images/smokefire-images.tar.gz"
  temporary_archive=""
  if [ ! -f "$archive" ]; then
    set -- ./images/smokefire-images.tar.gz.part*
    if [ ! -f "$1" ]; then
      echo "Offline image archive is missing from images/." >&2
      exit 1
    fi
    temporary_archive="./images/smokefire-images.assembled.tar.gz"
    rm -f "$temporary_archive"
    for part in "$@"; do
      echo "Assembling $(basename "$part")..."
      cat "$part" >> "$temporary_archive"
    done
    archive="$temporary_archive"
  fi

  trap 'if [ -n "$temporary_archive" ]; then rm -f "$temporary_archive"; fi' EXIT INT TERM
  docker image load --input "$archive"
  if [ -n "$temporary_archive" ]; then
    rm -f "$temporary_archive"
    temporary_archive=""
  fi
  trap - EXIT INT TERM
}

echo "[1/5] Verifying deployment files..."
./verify.sh

echo "[2/5] Checking Docker..."
docker info >/dev/null
docker compose version >/dev/null

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

app_image=$(env_value SMOKEFIRE_IMAGE)
if [ -z "$app_image" ]; then app_image="smokefire:1.0.0-cpu"; fi
service_port=$(env_value SMOKEFIRE_PORT)
if [ -z "$service_port" ]; then service_port="8600"; fi
go2rtc_image="alexxit/go2rtc:1.9.9"

echo "[3/5] Importing the prebuilt smokefire and go2rtc images when needed..."
if ! docker image inspect "$app_image" >/dev/null 2>&1 || ! docker image inspect "$go2rtc_image" >/dev/null 2>&1; then
  import_offline_images
else
  echo "Images $app_image and $go2rtc_image are already available."
fi

echo "[4/5] Starting smokefire..."
docker compose -p smokefire up -d

echo "[5/5] Waiting for readiness (up to 5 minutes)..."
attempt=1
while [ "$attempt" -le 60 ]; do
  if command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time 3 "http://127.0.0.1:${service_port}/api/health/ready" >/dev/null 2>&1; then
      echo "smokefire 1.0.0 is ready: http://127.0.0.1:${service_port}"
      if [ "$(env_value SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED)" = "true" ]; then
        echo "Existing go2rtc sync is enabled. Streams are imported from /api/streams automatically."
      fi
      exit 0
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q -T 3 -O /dev/null "http://127.0.0.1:${service_port}/api/health/ready"; then
      echo "smokefire 1.0.0 is ready: http://127.0.0.1:${service_port}"
      exit 0
    fi
  else
    echo "curl or wget is required for the readiness check." >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 5
done

docker compose -p smokefire ps
docker compose -p smokefire logs --tail 200 smokefire
echo "smokefire did not become ready within 5 minutes." >&2
exit 1
