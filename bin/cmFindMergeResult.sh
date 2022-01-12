#!/bin/bash
##################################################################
#
#	@author     Steffen Schmeissel
#
#   @brief      See usage message.
#
##################################################################

#set -x

fnUsage()
{
    echo ""
    echo "usage: `basename $0` <brtype> [vobtag1 vobtag2 ...] [-v | -vv | -w <nr_of_chars>]"
    echo ""
    echo "      Find resulting element versions after merge from <brtype>"
    echo "      in all vobs defined in CLEARCASE_AVOBS"
    echo ""
    echo "      An optionally list of vobtags redefines CLEARCASE_AVOBS"
    echo ""
    echo "      Default output format is config-spec compliant"
    echo "      -w : width             Minimum number of characters to be printed for element name [default=80]"
    echo "      -v : verbose mode      format - <hyperlink-ID> <from-version> -> <to-version>"
    echo "      -vv: more verbose mode format - <..have a look and get your own impression..>"
    echo ""
    echo "Error: $1"
    echo ""
}

CLEARCASE_AVOBS=${CLEARCASE_AVOBS:-""}
ctcmd="cleartool"
verbose=0
more_verbose=0
elem_with=80

if [ $# -lt 1 ];
then
    fnUsage "Missing required parameters."
    exit 5
fi

brtype=$1
shift

# get optional vobtags
reset_avobs=0
while [ $# -gt 0 ];
do
    # check verbose mode
    if [ $1 == "-w" ];
    then
        if [ ! -z $2 ];
        then
            elem_with=$2
            shift
        fi
        shift
        continue
    fi
    
    # check verbose mode
    if [ $1 == "-v" -a ${more_verbose} -eq 0 ];
    then
        verbose=1
        shift
        continue
    fi
    
    # check more-verbose mode
    if [ $1 == "-vv" ];
    then
        more_verbose=1
        verbose=0
        shift
        continue
    fi
    
    # get vobtags
    if [ $reset_avobs -eq 0 ];
    then
        CLEARCASE_AVOBS=""
        reset_avobs=1
    fi
    CLEARCASE_AVOBS="${CLEARCASE_AVOBS} $1"
    shift
done

#set -x
# check vob list
if [ -z "${CLEARCASE_AVOBS}" ];
then
    fnUsage "CLEARCASE_AVOBS not set!!"
    exit 6
fi

# publish it...
export CLEARCASE_AVOBS

# check CC-view
viewtag=$(${ctcmd} pwv -s)

# check view context
if [ "X-"${viewtag} == "X-" ];
then
    fnUsage "No ClearCase view context, use \"${ctcmd} setview <viewtag>\" OR \"cd snapshot <view-path>\""
    exit 7
fi

# check for dynamic OR snapshot view type
${ctcmd} lsview -prop -full ${viewtag} | grep Properties | grep snapshot > /dev/null 2>&1
dynview=$?

hlist=`${ctcmd} find -avobs -vers "brtype(${brtype}) && hltype(Merge,->)" -exec 'cleartool desc -l $CLEARCASE_XPN' -print \
        | grep '\->' | grep Merge | sort -ru | awk '{ print $1;}'`

for h in ${hlist};
do
    if [ ${more_verbose} -eq 1 ];
    then
        ${ctcmd} descr -l hlink:${h}
    elif [ ${verbose} -eq 1 ];
    then
        ${ctcmd} descr -l hlink:${h} | grep -v hyperlink | grep Merge
    else
        elemstr=$(${ctcmd} descr -l hlink:${h} | grep -v hyperlink | grep Merge | awk '{ print $4;}' | sed -e 's/@/ /g');
        elem=$(echo $elemstr | awk '{ print $1; }');

        if [ ${dynview} -eq 0 ];
        then
            snviewroot=$(${ctcmd} pwv -root)
            elem=$(echo $elem | sed "s!${snviewroot}!!");
        fi
        vers=$(echo $elemstr | awk '{ print $2;}');
        echo "${elem} ${vers}" | awk '{ printf "element %-'${elem_with}'s\t%s\n", $1, $2; }';
    fi
done
