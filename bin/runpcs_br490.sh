#! /bin/bash
echo "Using VIEW=$VIEW"
rm -rf mdt_results/*
time $VIEW/tisc_pcs/pcs/tst/scripts/run_tests.sh -v $VIEW -p BR490 -b $VIEW/../build/pcsmdt -c pcs_br490.conf

RESULT="Not set."

cat $(find mdt_results -name summary) | grep FAIL

