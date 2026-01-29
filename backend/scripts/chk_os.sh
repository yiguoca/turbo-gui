#!/usr/bin/env bash
##------------------------------------------------
## list OS type of servers and generate list with OS type; 
##     and also generate CentOS host list.
##
## Usage: $0 <env>
## the <env> could be one of dev, pp, prod, q1, q2, st, test, uat
## input file: $BACKEND_DIR/data/list.${env}.ssh
## output file: $BACKEND_DIR/data/list.${env}.os
## output file: $BACKEND_DIR/data/list.${env}.centos
##------------------------------------------------

f_prt_usage () {
  echo "Usage: $pgm <env>"
  echo "       <env> is one of  dev, pp, prod, q1, q2, st, test, uat"
  echo "Example: $pgm dev"
  exit 1
}
##-----------------------------

fetch_host_info() {
    local host="$1"
    local ssha="$2"

    # Combine all commands into ONE SSH call
    local result
    result=$("$ssha" "$host" "
        . /etc/os-release 2>/dev/null && echo \"\$ID\"
        nproc 2>/dev/null
        awk '/MemTotal/ {print \$2}' /proc/meminfo 2>/dev/null
    " 2>/dev/null)

    if [[ $? -ne 0 || -z "$result" ]]; then
        printf "%-40s%-20s%-10s%-12s\n" "$host" "ssh failed" "N/A" "N/A"
        return
    fi

    # Parse results (3 lines: os, cpu, mem)
    local ostype cpu mem_kb mem
    ostype=$(echo "$result" | sed -n '1p')
    cpu=$(echo "$result" | sed -n '2p')
    mem_kb=$(echo "$result" | sed -n '3p')

    # Normalize OS type
    case "$ostype" in
        centos) ostype="CentOS" ;;
        rhel)   ostype="RedHat" ;;
        ubuntu) ostype="Ubuntu" ;;
        "")     ostype="N/A" ;;
    esac

    # Convert memory KB to GiB
    if [[ -n "$mem_kb" && "$mem_kb" =~ ^[0-9]+$ ]]; then
        (( mem = (mem_kb + 524288) / 1048576 ))
    else
        mem="N/A"
    fi

    [[ -z "$cpu" ]] && cpu="N/A"

    printf "%-40s%-20s%-10s%-12s\n" "$host" "$ostype" "$cpu" "$mem"
}

export -f fetch_host_info

# ------------------------------
# Main
# ------------------------------
pgm=${0##*/}
[[ $# -lt 1 ]] && f_prt_usage
env=$1

INPUT_FILE=$BACKEND_DIR/data/list.${env}.ssh
if [ ! -s "$INPUT_FILE" ]; then
   echo "$INPUT_FILE not exist or empty!"
   exit 1
fi

OUTPUT_FILE=$BACKEND_DIR/data/list.${env}.os
CentOS_FILE=$BACKEND_DIR/data/list.${env}.centos
> $OUTPUT_FILE
> $CentOS_FILE

MAX_PARALLEL=20

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Warning: $INPUT_FILE not found, skipping." >&2
        continue
    fi
# start heartbeat (dot every 2 seconds)
heartbeat() {
  while :; do
    printf "."
    sleep 2
  done
}

heartbeat &
HB_PID=$!

{
    printf "%-40s%-20s%-10s%-12s\n" "Hostname" "OS" "CPU" "Memory(GB)"

    tmpfile="${OUTPUT_FILE}.tmp"

    # Run in parallel (macOS compatible)
    # Using grep -w inside the loop to ensure exact hostname matching
    grep -Ev '^(#|[[:space:]]*$)' "$INPUT_FILE" | \
        xargs -n1 -P"$MAX_PARALLEL" -I{} bash -c 'fetch_host_info "$1" "$2"' _ {} "/usr/bin/ssh" \
        > "$tmpfile"

    # Output in original host order
    while read -r host; do
        # Use -w to prevent partial matches (e.g. host "db1" matching "db10")
        grep -w "^${host}" "$tmpfile" || printf "%-40s%-20s%-10s%-12s\n" "$host" "not found" "N/A" "N/A"
    done < <(grep -Ev '^(#|[[:space:]]*$)' "$INPUT_FILE")

    rm -f "$tmpfile"
    echo
} |tee $OUTPUT_FILE

# stop heartbeat
kill "$HB_PID" 2>/dev/null
wait "$HB_PID" 2>/dev/null

cat $OUTPUT_FILE |grep CentOS|awk '{print $1}' > $CentOS_FILE
