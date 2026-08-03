#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"

if [ ! -f SHA256SUMS ]; then
  echo "SHA256SUMS is missing." >&2
  exit 1
fi

sha256sum -c SHA256SUMS

