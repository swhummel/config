#!/bin/bash

# check PIS and TcmsGenSw VOB for:
# - special selection (usually some missing update)
# - hijacked files
# - view-private files

COL_ON="\033[33;40m"
COL_OFF="\033[0m"

function checkVob()
{
    echo -e "${COL_ON}checking for special selection, hijacked and missing files...${COL_OFF}"
    echo cleartool -e 'l ls -r | egrep "special sel|hijacked|loaded but missing"'
    cleartool ls -r | egrep "special sel|hijacked|loaded but missing"

    echo -e "${COL_ON}show view-private files... (ignore va_root)${COL_OFF}"
    echo -e 'cleartool ls -rec -view_only | egrep -v "/var/" | egrep -v "va_root$"'
    cleartool ls -rec -view_only | egrep -v "/var/" | egrep -v "va_root$"
}

echo "Attention: looking only in \$VIEW/PIS/"
echo -e "${COL_ON}in ${VIEW}/PIS...${COL_OFF}"
cd ${VIEW}/PIS
checkVob

#echo -e "${COL_ON}in ${VIEW}/TcmsGenSw/lib...${COL_OFF}"
#cd ${VIEW}/TcmsGenSw/lib
#checkVob

#echo -e "${COL_ON}in ${VIEW}/TcmsGenSw/tools...${COL_OFF}"
#cd ${VIEW}/TcmsGenSw/tools
#checkVob

echo -e "${COL_ON}search for checkouts (checked-out dirs are not shown by -view_only)...${COL_OFF}"
echo -e 'cleartool lsco -me -avobs -cview'
cleartool lsco -me -avobs -cview
