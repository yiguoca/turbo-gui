#!/bin/bash
##------------------------------------------------
## check if servers in a list pingable
## Usage: $0 <env>
## the <env> could be one of dev, pp, prod, q1, q2, st, test, uat
## input file: $BACKEND_DIR/data/list.${env}.hosts
## output file: $BACKEND_DIR/data/list.${env}.ping
##------------------------------------------------

f_prt_usage () {
  echo "Usage: $pgm <env>"
  echo "       <env> is one of  dev, pp, prod, q1, q2, st, test, uat"
  echo "Example: $pgm dev"
  exit 1
}
##-----------------------------

pgm=${0##*/}
[[ $# -lt 1 ]] && f_prt_usage
env=$1

INPUT_FILE=$BACKEND_DIR/data/list.${env}.hosts
OUTPUT_FILE=$BACKEND_DIR/data/list.${env}.ping
> $OUTPUT_FILE

cat $INPUT_FILE | egrep -v "^ *#|^ *$" | while read host; do
    printf "%-40s" $host;
    if ping -c 1 -t 2 "$host" &>/dev/null; then
       printf "%-40s%s\n" " " "ping OK"
       echo $host >> $OUTPUT_FILE
    else
       printf "%-40s%-10s\n" " " "ping failed"
    fi
done 

echo "pingable hosts saved in $OUTPUT_FILE"
