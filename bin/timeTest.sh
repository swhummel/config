#! /bin/bash
#
# script zur Laufzeitanzeige der Uebergebenen Commands

if [ $# -eq 0 ]; then
  echo "no param"
  exit -1
fi

start=$(date +%s)

# get all arguments
args=("$@")

count=0
while [ $count -lt $# ]
do
  echo " *** ${args[$count]} *** "
  `echo ${args[$count]}`
  let count=$count+1
done

end=$(date +%s)

let diff=$end-$start
echo "*** runtime=$diff ***"
exit 0
