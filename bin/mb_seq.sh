#! /bin/bash +x

if [ $# -ne 1 ]; then
    echo "usage: $0 reqex for mb -l"
    exit 1
fi

countBuildTargets=$(mb -l | egrep -i $1 | wc -l)
echo "Found $countBuildTargets build targets with $1"

buildTargetIndex=0;
for buildTarget in $(mb -l | egrep -i $1 | cut -d" "  -f 2); do
    let "buildTargetIndex+=1"
    mb -n $buildTarget > build.out 2>&1;

    if [ $? -eq 0 ]
    then
        msg="successful";
    else
        msg="failed";
    fi

    echo -e "$buildTargetIndex/$countBuildTargets - $buildTarget $msg";
done
rm build.out
