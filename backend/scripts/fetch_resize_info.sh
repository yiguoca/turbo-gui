#!/bin/bash
##--------------------------------------------------------------
## retrive the RESIZE Action from Turbonomic
##
## input file: $BACKEND_DIR/data/list.${env}.${OStype}.uuids
##
##--------------------------------------------------------------

f_prt_usage () {
  echo "Usage: $pgm <env>"
  echo "       <env> is one of  dev, pp, prod, q1, q2, st, test, uat"
  echo "Example: $pgm dev"
  exit 1
}
##------------------------------------------------------------
f_get_resize_detail () {
    local VM_UUID=$1
    local URL="https://turbonomic.autodatacorp.org/api/v3/entities/${VM_UUID}/actions"

    curl -k -s -b "$COOKIE_FILE" "$URL" | jq -r '
      .[] |
      if .actionType == "RESIZE" then
        # Create a lowercase version of the details string for matching
        (.details | ascii_downcase) as $details_lower |
        if $details_lower | test("vcpu") then
          "CPU: \(.currentValue | tonumber | floor) \(.newValue | tonumber | floor)"
        elif $details_lower | test("vmem") then
          "Mem: \((.currentValue | tonumber) / 1024 / 1024) \((.newValue | tonumber) / 1024 / 1024)"
        else
          empty
        end
      else
        empty
      end
    '
}

##-----------------------------
# Main
##-----------------------------

pgm=${0##*/}
[[ $# -lt 1 ]] && f_prt_usage
env=$1
ostype=$OSTYPE

INPUT_FILE=$BACKEND_DIR/data/list.${env}.${ostype}.uuids
if [ ! -s "$INPUT_FILE" ]; then
   echo "$INPUT_FILE not exist or empty!"
   exit 1
fi

COOKIE_FILE="$BACKEND_DIR/data/cookie.txt"

chk_cookie.sh 

while read -r host uuid; do
    echo "$host ...";
    f_get_resize_detail "$uuid" |while read item current new; do
       printf "%-30s%-8s%-8s\n" $item $current $new
    done
    echo;
done < <(awk '{print $1, $6}' $INPUT_FILE )

exit
