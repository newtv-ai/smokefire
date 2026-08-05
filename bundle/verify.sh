#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"

if [ ! -f SHA256SUMS ]; then
  echo "SHA256SUMS is missing." >&2
  exit 1
fi

# --quiet 只打印失败的文件。start.sh 每次启动都会调用这里，逐个文件刷一遍太吵。
if ! sha256sum -c --quiet SHA256SUMS; then
  echo "Verification failed. Re-download the files listed above." >&2
  exit 1
fi

echo "Verified $(grep -cE '^[0-9a-fA-F]{64}[[:space:]]' SHA256SUMS) files."

