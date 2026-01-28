#!/usr/bin/env bash
set -e
jq -r '.entities[] | [.displayName,.uuid,.state,(.numVCPUs//"N/A"),(.memory//"N/A")] | @tsv' "$BACKEND_DIR/data/vms_raw.json" > "$BACKEND_DIR/data/vms_parsed.tsv"
