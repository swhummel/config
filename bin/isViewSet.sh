#! /bin/bash
echo "*************************************************"
echo "VIEW set to: $VIEW"
if [ -z "$VIEW" ]; then
    echo "Error: VIEW not set"
    exit 1
else
    echo $VIEW | egrep '.*/vobs.*'
    ISSNAPSHOT=$?

    echo $VIEW | egrep '^\/view'
    ISDYNAMIC=$?

    if [ $ISSNAPSHOT -ne 0 ] && [ $ISDYNAMIC -ne 0 ]; then
        echo "Error: wrong directory set to VIEW"
        exit 2
    fi
fi
echo "*************************************************"

pwd | egrep $VIEW
ISINVIEW=$?

pwd | egrep /usr/local/bt/
#pwd | egrep /usr/local/bt/Modultest
ISINMODULTEST=$?

if [ $ISINVIEW -ne 0 ] && [ $ISINMODULTEST -ne 0 ]; then
   echo "Error: you are not in directory $VIEW"
   exit 1
fi

exit 0
