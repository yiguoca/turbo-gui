#!/usr/bin/env bash
set -e
curl -ks -c "$BACKEND_DIR/data/cookie.txt" -X POST "$TURBO_URL$LOGIN_ENDPOINT" -d @"$CREDS_FILE"
