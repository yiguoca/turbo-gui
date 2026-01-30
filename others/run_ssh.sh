#!/usr/bin/env bash
##------------------------------------------------
## run_ssh: Execute command on multiple hosts in parallel
##
## Usage: run_ssh [<file>] <"command">
##   - If only one argument, filename defaults to "list"
##   - Runs command on each host in parallel
##   - Output sorted in same order as input file
##   - Multi-line output converted to single line (| separator)
##   - Results saved to ${script_name}.log
##
## Example: run_ssh "uname -a"
##          run_ssh hosts.txt "df -h"
##------------------------------------------------

f_prt_usage() {
  echo "Usage: $pgm [<file>] <\"command\">"
  echo "   <file>      - file containing list of hostnames (default: list)"
  echo "   <command>   - command to run on each host (required)"
  echo ""
  echo "Example: $pgm \"uname -a\""
  echo "         $pgm hosts.txt \"df -h\""
  exit 1
}

##-----------------------------
## Execute command on a single host
##-----------------------------
execute_on_host() {
    local host="$1"
    local cmd="$2"
    
    # Run command via ssh and capture output
    local result
    result=$(/usr/bin/ssh "$host" "$cmd" 2>&1)
    local exit_code=$?
    
    # Filter out only the specific SSH banner/legal notice lines
    result=$(echo "$result" | grep -v "^\*\* ATTENTION:" | grep -v "^Authentication attempts")
    
    # Convert multi-line output to single line (separated by |)
    result=$(echo "$result" | tr '\n' '|' | sed 's/|$//')
    
    if [[ $exit_code -ne 0 ]]; then
        echo "${host}|[SSH_FAILED]|${result}"
    else
        echo "${host}|${result}"
    fi
}

export -f execute_on_host

##-----------------------------
## Heartbeat function
##-----------------------------
heartbeat() {
  while :; do
    printf "."
    sleep 2
  done
}

##-----------------------------
## Main
##-----------------------------
pgm=${0##*/}

# Parse arguments
if [[ $# -lt 1 ]]; then
    f_prt_usage
elif [[ $# -eq 1 ]]; then
    # Only command provided, use default filename
    INPUT_FILE="list"
    CMD="$1"
elif [[ $# -eq 2 ]]; then
    # File and command provided
    INPUT_FILE="$1"
    CMD="$2"
else
    f_prt_usage
fi

# Validate input file
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

if [[ ! -s "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' is empty!"
    exit 1
fi

OUTPUT_FILE="${pgm}.log"
MAX_PARALLEL=20

# Start heartbeat
heartbeat &
HB_PID=$!

{
    tmpfile="${OUTPUT_FILE}.tmp"
    
    # Run commands in parallel
    grep -Ev '^(#|[[:space:]]*$)' "$INPUT_FILE" | \
        xargs -n1 -P"$MAX_PARALLEL" -I{} bash -c 'execute_on_host "$1" "$2"' _ {} "$CMD" \
        > "$tmpfile"
    
    # Sort output in original host order
    while read -r host; do
        # Find host in results and format output
        line=$(grep "^${host}|" "$tmpfile")
        if [[ -z "$line" ]]; then
            echo "${host}|[NOT_FOUND]"
        else
            echo "$line"
        fi
    done < <(grep -Ev '^(#|[[:space:]]*$)' "$INPUT_FILE")
    
    rm -f "$tmpfile"
    echo
} | tee "$OUTPUT_FILE"

# Show summary of failed hosts
echo ""
echo "=== Summary ==="
failed_count=$(grep -c "\[SSH_FAILED\]" "$OUTPUT_FILE")
total_count=$(grep -cv "^\[" "$OUTPUT_FILE")

if [[ $failed_count -gt 0 ]]; then
    echo "Failed hosts ($failed_count):"
    grep "\[SSH_FAILED\]" "$OUTPUT_FILE" | cut -d'|' -f1
else
    echo "All hosts completed successfully!"
fi

# Stop heartbeat
kill "$HB_PID" 2>/dev/null
wait "$HB_PID" 2>/dev/null

echo ""
echo "Results saved to: $OUTPUT_FILE"
