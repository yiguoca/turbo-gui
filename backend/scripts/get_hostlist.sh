#!/bin/bash
##--------------------------------------------------------
## generate list of hostname for all the cpp environments
## input:   $BACKEND_DIR/data/list.allvms
## output:  $BACKEND_DIR/data/list.${env}.hosts
##--------------------------------------------------------

INPUT_FILE="$BACKEND_DIR/data/list.allvms"

while read env pattern; do
    echo "Processing $env with pattern $pattern"
    outfile="$BACKEND_DIR/data/list.${env}.hosts"
    > "$outfile"
    # Use -- to avoid '-' being treated as option
    awk '{print tolower($3)}' "$INPUT_FILE" | grep -Ei -- "$pattern" > "$outfile"
done <<EOF
dev    -d.*cp-x
pp     -ppcp-x
prod   -prcp-x
q1     -(qacp|q1cp)-x
q2     -q2cp-x
st     -stcp-x
test   -tecp-x
uat    -u1cp-x
linux  -....-x
cpp    -..cp-x
EOF

echo "Host lists generated:"
ls -l $BACKEND_DIR/data/list.*.hosts
