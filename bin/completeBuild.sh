#!/bin/bash

CSNAME=""
if [ $# -eq 0 ]; then
    CSNAME="etp_pis_v1_latest.cs"
else
    CSNAME=$1
fi

date +%H:%M:%S

# update config spec directory and set config spec freshly
echo "updating cs-directory..."
cd ${VIEW}/PIS/common/config-spec
cleartool update . 2>&1 >csupdate.log
echo "setting cs: $CSNAME..."
cleartool setcs $CSNAME 2>&1 >>csupdate.log
echo "update -rename PIS..."
cleartool update -rename ${VIEW}/PIS 2>&1 >>csupdate.log
echo "update -rename TcmsGenSw..."
cleartool update -rename ${VIEW}/TcmsGenSw 2>&1 >>csupdate.log

date +%H:%M:%S

# clean all
echo "cleaning..."
cd ${VIEW}
cleanall.sh

# check view for CHECKEDOUTs, hijacked files, private files...
checkView.sh

# run target build (first so we end with colinux settings after this... :) )
### . mktarget.sh

# run colinux build
. mkcolinux.sh


