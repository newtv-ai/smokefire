#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
docker compose -p smokefire down
echo "smokefire stopped. The smokefire-data volume was preserved."

