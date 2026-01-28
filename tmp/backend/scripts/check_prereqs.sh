#!/usr/bin/env bash
set -e
REQUIRED=(curl jq awk sed)
for bin in "${REQUIRED[@]}"; do
  command -v "$bin" >/dev/null || { echo "Missing $bin"; exit 1; }
done
