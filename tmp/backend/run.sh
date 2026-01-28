#!/usr/bin/env bash
set -e

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BACKEND_DIR

LOG_DIR="$BACKEND_DIR/logs"
LOG_FILE="$LOG_DIR/run.log"
mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== Turbonomic VM Collection ====="

source "$BACKEND_DIR/config/env.sh"
source "$BACKEND_DIR/config/endpoints.sh"

bash "$BACKEND_DIR/scripts/check_prereqs.sh"

if ! bash "$BACKEND_DIR/scripts/check_cookie.sh"; then
  echo "[INFO] Cookie missing or invalid → logging in"
  bash "$BACKEND_DIR/scripts/login.sh"
fi

bash "$BACKEND_DIR/scripts/get_all_vms.sh"
bash "$BACKEND_DIR/scripts/parse_vms.sh"

echo "===== DONE ====="
