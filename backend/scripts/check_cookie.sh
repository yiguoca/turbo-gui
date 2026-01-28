#!/usr/bin/env bash
set -e
COOKIE="$BACKEND_DIR/data/cookie.txt"
[[ -s "$COOKIE" ]] && grep -qi JSESSIONID "$COOKIE"
