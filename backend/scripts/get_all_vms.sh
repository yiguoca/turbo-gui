#!/bin/bash
##-----------------------------------------
## Fetch all the VMs info from Turbonomic
## 
## output file1: the raw json format file:   "$BACKEND_DIR/data/vms_raw.json"
## output file2: list of all the VMs: $BACKEND_DIR/data/list.allvms
##-----------------------------------------

chk_cookie.sh

# --- Configuration ---
COOKIE_FILE="$BACKEND_DIR/data/cookie.txt"

BASE_URL="${TURBO_URL}${VMS_ENDPOINT}?types=VirtualMachine&limit=500"

OUTPUT_FILE="$BACKEND_DIR/data/vms_raw.json"
TEMP_HEADER_FILE="$BACKEND_DIR/log/response_headers.txt"
LIST_ALLVMS_FILE="$BACKEND_DIR/data/list.allvms"

# --- Start Fresh ---
echo "[]" > "$OUTPUT_FILE"

# --- Initial Request ---
echo "Fetching first page..."
curl -s -k -b "$COOKIE_FILE" -D "$TEMP_HEADER_FILE" "$BASE_URL" > page_1.json

# Check for data and merge
if ! jq -e '.[0]' page_1.json > /dev/null; then
    echo "Initial request returned no data. Check API and cookies. Exiting."
    rm page_1.json
    exit 1
fi
jq -s '.[0] + .[1]' "$OUTPUT_FILE" page_1.json > temp_merged.json && mv temp_merged.json "$OUTPUT_FILE"
rm page_1.json

# --- Paginate ---
page_num=2
while true; do
  # CORRECTED: Use 'x-next-cursor' to get the cursor value
  CURSOR=$(grep -i "x-next-cursor" "$TEMP_HEADER_FILE" | awk -F': ' '{print $2}' | tr -d '\r')

  if [ -z "$CURSOR" ]; then
    echo "No more pages. All VMs fetched."
    break
  fi

  echo "Fetching next page with cursor: $CURSOR"

  # CORRECTED: Make the next request by adding the cursor as a URL parameter
  PAGINATION_URL="${BASE_URL}&cursor=${CURSOR}"
  curl -s -k -b "$COOKIE_FILE" -D "$TEMP_HEADER_FILE" "$PAGINATION_URL" > "page_${page_num}.json"

  # If the new page is empty or not a valid array, stop.
  if ! jq -e '.[0]' "page_${page_num}.json" > /dev/null; then
      echo "Received empty or invalid data on page ${page_num}. Assuming end of results."
      rm "page_${page_num}.json"
      break
  fi

  # Merge the new results
  jq -s '.[0] + .[1]' "$OUTPUT_FILE" "page_${page_num}.json" > temp_merged.json && mv temp_merged.json "$OUTPUT_FILE"
  rm "page_${page_num}.json"

  ((page_num++))
done

# --- Cleanup ---
rm "$TEMP_HEADER_FILE"
TOTAL_VMS=$(jq '. | length' "$OUTPUT_FILE")
echo "Total VMs fetched: $TOTAL_VMS. Saved to $OUTPUT_FILE"

cat  $OUTPUT_FILE|jq -r '.[] | "\(.displayName) \(.uuid)"'  > $LIST_ALLVMS_FILE
echo "List of all VMs saved in $LIST_ALLVMS_FILE"

exit
