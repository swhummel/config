#!/bin/bash
# changesSinceMerge.sh - dump changes (and who did them) since last merged version

if [ $# -lt 2 ]; then
    APP=`basename $0`
    echo "typical usage: ct findmerge . -fver .../umr3.5_nbl5_fixes/LATEST -print -nxn | $APP <from_branch> <to_branch>"
    echo "or (merged files are checked out): lsco -s | $APP <from_branch> <to_branch>"
    exit 1;
fi

FROM_BRANCH=$1
TO_BRANCH=$2

while read FILE; do

    SRC_LATEST=`cleartool find $FILE -d -version "version(.../$FROM_BRANCH/LATEST)" -print | sed 's!\\\\!/!g'`
    echo "$SRC_LATEST..."

    LAST_MERGED_TO_DEST=""

    # get a list of all versions that have a merge arrow pointing away FROM that version
    MERGED_SRC_VERSIONS=`cleartool find $FILE -d -version "brtype($FROM_BRANCH) && hltype(Merge,->)" -print | sed 's!\\\\!/!g'`

    # for each version that was merged...
    for SRC in $MERGED_SRC_VERSIONS; do

        #echo "check merges FROM $SRC"

        # where TO was it merged?
        MERGE_TARGETS=`cleartool desc -ahlink "Merge" $SRC | grep "Merge ->" | sed 's!\\\\!/!g' | awk '{print $3}'`

        # if it was merged to our dest branch, remember this version
        MERGE_TARGET=`printf "%s\n" "$MERGE_TARGETS" | grep "$TO_BRANCH/[0-9][0-9]*"`

        # and, remember the last version found that way
        if [ "$MERGE_TARGET" != "" ] ; then
            LAST_MERGED_TO_DEST=$SRC
        fi

    done

    if [ "$LAST_MERGED_TO_DEST" != "" ] ; then
        #echo "                 last merged version found: <$LAST_MERGED_TO_DEST>"
        CHECK_FROM=`echo $LAST_MERGED_TO_DEST | sed 's!.*/\(.*\)!\1!'`
    else
        #echo "                 no prior merge found."
        CHECK_FROM=0
    fi
    #echo "checking from version $CHECK_FROM"

    CHECK_TO=`echo $SRC_LATEST | sed 's!.*/\(.*\)!\1!'`
    let CHECK_FROM=$CHECK_FROM+1

    if [ "$CHECK_TO"x = ""x ]; then
        echo "sorry: can't deduce 'CHECK_TO' version from <$SRC_LATEST> - misspelled branch name?"
    else

        echo "from $CHECK_FROM, to $CHECK_TO"
        if [ $CHECK_FROM -le $CHECK_TO ] ; then

            # erase old comment
            cleartool chevent -replace -c "" $FILE

            # add new comment lines
            BASE=`echo $SRC_LATEST | sed 's!\(.*\)/.*!\1!'`
            for v in `seq $CHECK_FROM $CHECK_TO` ; do
                THISCMT=`cleartool desc -fmt "    %-c" $BASE/$v`
                cleartool chevent -append -c "autocmt- $THISCMT" $FILE
            done
        else
            echo "INTERNAL ERROR: all versions already merged??"
        fi
    fi
    echo

done
