#!/bin/bash
##------------------------------------------------
## check if servers in a list sshable
## Usage: $0 <env>
## the <env> could be one of dev, pp, prod, q1, q2, st, test, uat
## input file: $BACKEND_DIR/data/list.${env}.ping
## output file: $BACKEND_DIR/data/list.${env}.ssh
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

INPUT_FILE=$BACKEND_DIR/data/list.${env}.ping
OUTPUT_FILE=$BACKEND_DIR/data/list.${env}.ssh
> $OUTPUT_FILE

cat $INPUT_FILE | egrep -v "^ *#|^ *$" | while read host; do
    printf "%-40s" $host;
       /usr/bin/ssh -o StrictHostKeyChecking=no \
           -o ConnectTimeout=30 \
           -o BatchMode=yes \
           $host -n : 2>/dev/null;
    if [[ $? -ne 0 ]]; then 
         printf "%-40s%-10s\n" " " "ssh failed"; 
       else
         printf "\n"
         echo $host >> $OUTPUT_FILE
    fi
done 

echo "sshable hosts saved in $OUTPUT_FILE"
