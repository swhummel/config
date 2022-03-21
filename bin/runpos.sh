#! /bin/bash
if [ $# -ne 2 ]; then
    echo "usage: $0 PROJECT test_applist_file"
    exit 1
fi

export NTP_SERVER_IP=pool.ntp.org
export TZ=UTC

isViewSet.sh
if [ $? -ne 0 ]; then
    exit 2
fi

TESTDIR=/usr/local/bt/Moduletests
cd $TESTDIR

echo "Using VIEW=$VIEW"
rm -rf mdt_results/*

taskset --cpu-list 0 $VIEW/tisc_pos/positioning/tst/scripts/run_tests.sh -v $VIEW -b $VIEW/../build/posmdt$1 -c $2

RESULT="Not set."

#mdt_results/2022.02.04-22.11.12/summary mdt_results/2022.02.04-22.11.12/STD/summary
#cat $(find mdt_results -name summary)
echo "*****************"
grep FAIL $(find mdt_results -name summary)

