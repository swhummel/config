#! /bin/bash
#
# usage_ $0 <username>

if [ 0 -eq $# ]; then
    export USERNAME=-me
else
    export USERNAME=$1
fi

cleartool lsh -r -user $USERNAME -since today       | \
sed 's!.*create.*version "!element /!'              | \
awk -F "@" '{ printf "%-80s %s\n", $1, $3; }'       | \
sort -u
