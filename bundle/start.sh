#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"

echo "[1/5] Verifying deployment files..."
./verify.sh

echo "[2/5] Checking Docker..."
docker info >/dev/null
docker compose version >/dev/null

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

echo "[3/5] Importing the prebuilt image when needed..."
if ! docker image inspect smokefire:1.0.0-cpu >/dev/null 2>&1; then
  docker image load --input ./images/smokefire-1.0.0-cpu.tar.gz
else
  echo "Image smokefire:1.0.0-cpu is already available."
fi

echo "[4/5] Starting smokefire..."
docker compose -p smokefire up -d

echo "[5/5] Waiting for readiness (up to 5 minutes)..."
attempt=1
while [ "$attempt" -le 60 ]; do
  if command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time 3 http://127.0.0.1:8600/api/health/ready >/dev/null 2>&1; then
      echo "smokefire 1.0.0 is ready: http://127.0.0.1:8600"
      exit 0
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q -T 3 -O /dev/null http://127.0.0.1:8600/api/health/ready; then
      echo "smokefire 1.0.0 is ready: http://127.0.0.1:8600"
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

