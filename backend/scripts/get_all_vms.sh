#!/usr/bin/env bash
set -e
curl -ks -b "$BACKEND_DIR/data/cookie.txt" -X POST "$TURBO_URL$VMS_ENDPOINT" -d '{"className":"VirtualMachine"}' -o "$BACKEND_DIR/data/vms_raw.json"
