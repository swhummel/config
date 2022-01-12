#! /bin/bash
echo "Using VIEW=$VIEW"
rm -rf mdt_results/*

time $VIEW/tisc_pcs/pcs/tst/scripts/run_tests.sh -v $VIEW -b $VIEW/../build/pcsmdtC30 -c pcs.conf
#taskset -cpu-list 0 'time $VIEW/tisc_pcs/pcs/tst/scripts/run_tests.sh -v $VIEW -b $VIEW/../build/pcsmdtC30 -c pcs.conf'



#taskset -cpu-list 0 time $VIEW/tisc_pcs/pcs/tst/scripts/run_tests.sh -v $VIEW -b $VIEW/../build/pcsmdtSTD -c pcs.conf
#taskset -cpu-list 0 time $VIEW/tisc_pcs/pcs/tst/scripts/run_tests.sh -v $VIEW -b $VIEW/../build/pcsmdtBR430R -c pcs.conf

RESULT="Not set."

cat $(find mdt_results -name summary) | grep FAIL

