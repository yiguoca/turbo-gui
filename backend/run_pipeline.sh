#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# run_pipeline.sh
# --------------------------------------------
# Usage:
#   ./run_pipeline.sh <env>
# --------------------------------------------

pgm=${0##*/}

usage() {
  echo "Usage: $pgm <env>"
  echo "  <env> must be one of: dev pp prod q1 q2 st test uat"
  exit 1
}

[[ $# -ne 1 ]] && usage
env=$1

case "$env" in
  dev|pp|prod|q1|q2|st|test|uat) ;;
  *) usage ;;
esac

# ----------------------------
# Load environment FIRST
# ----------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

. "$SCRIPT_DIR/config/endpoints.sh"
. "$SCRIPT_DIR/config/env.sh"

# ----------------------------
# Canonical script location
# ----------------------------
SCRIPTS="$BACKEND_DIR/scripts"

# ----------------------------
# Sanity checks
# ----------------------------
required_scripts=(
  chk_cookie.sh
  get_all_vms.sh
  get_hostlist.sh
  chk_ping.sh
  chk_ssh.sh
  chk_os.sh
  get_uuid.sh
  mk_mdtable.sh
)

for s in "${required_scripts[@]}"; do
  [[ -x "$SCRIPTS/$s" ]] || {
    echo "[ERROR] Missing or non-executable: $SCRIPTS/$s"
    exit 1
  }
done

step() {
  echo
  echo "=================================================="
  echo "[STEP] $1"
  echo "=================================================="
}

echo "[INFO] Environment: $env"
echo "[INFO] OSTYPE: $OSTYPE"
echo "[INFO] BACKEND_DIR: $BACKEND_DIR"

# ----------------------------
# Pipeline
# ----------------------------
step "1. Validate / refresh cookie"
"$SCRIPTS/chk_cookie.sh"

step "2. Fetch all VMs"
"$SCRIPTS/get_all_vms.sh"

step "3. Generate host lists"
"$SCRIPTS/get_hostlist.sh"

step "4. Ping check ($env)"
"$SCRIPTS/chk_ping.sh" "$env"

step "5. SSH check ($env)"
"$SCRIPTS/chk_ssh.sh" "$env"

step "6. OS detection ($env)"
"$SCRIPTS/chk_os.sh" "$env"

step "7. UUID generation ($env)"
"$SCRIPTS/get_uuid.sh" "$env"

step "8. Markdown table ($env)"
"$SCRIPTS/mk_mdtable.sh" "$env"

echo
echo "=================================================="
echo "[SUCCESS] Pipeline completed"
echo "Output:"
echo "  $BACKEND_DIR/data/table.${env}.${OSTYPE}.md"
echo "=================================================="
