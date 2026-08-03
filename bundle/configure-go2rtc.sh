#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"

mode=${1:-}
api=${2:-}
rtsp=${3:-}

if [ "$mode" != "direct" ] && [ "$mode" != "builtin" ] && [ "$mode" != "upstream" ]; then
  echo "Usage: $0 direct|builtin|upstream [API_BASE RTSP_BASE]" >&2
  exit 2
fi

if [ ! -f .env ]; then cp .env.example .env; fi

set_env() {
  key=$1
  value=$2
  temp_file=".env.smokefire.tmp"
  awk -v key="$key" -v value="$value" '
    BEGIN { found = 0 }
    index($0, key "=") == 1 { print key "=" value; found = 1; next }
    { print }
    END { if (!found) print key "=" value }
  ' .env > "$temp_file"
  mv "$temp_file" .env
}

case "$mode" in
  direct)
    set_env SMOKEFIRE_GO2RTC_ENABLED false
    set_env SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED false
    echo "Direct RTSP mode configured. Add camera/NVR URLs in smokefire."
    ;;
  builtin)
    set_env SMOKEFIRE_GO2RTC_ENABLED true
    set_env SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED false
    echo "Bundled go2rtc mode configured. Cameras added in smokefire will be fanned out automatically."
    ;;
  upstream)
    if [ -z "$api" ] || [ -z "$rtsp" ]; then
      echo "Upstream mode requires API_BASE and RTSP_BASE." >&2
      exit 2
    fi
    set_env SMOKEFIRE_GO2RTC_ENABLED false
    set_env SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED true
    set_env SMOKEFIRE_UPSTREAM_GO2RTC_API "${api%/}"
    set_env SMOKEFIRE_UPSTREAM_GO2RTC_RTSP "${rtsp%/}"
    echo "Existing go2rtc configured. All main streams from GET /api/streams will be imported automatically."
    ;;
esac

if running=$(docker compose -p smokefire ps --status running -q smokefire 2>/dev/null) && [ -n "$running" ]; then
  docker compose -p smokefire up -d --force-recreate smokefire
  echo "smokefire was restarted with the new video source mode."
else
  echo "Run ./start.sh to start smokefire with this configuration."
fi

