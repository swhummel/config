#! /bin/bash

# ~/tmp/cherrypick_880300 is created by:
#   git find 880399

#   git find is an alias:
#       find = log --pretty=\"format:%Cgreen%H %Cblue%s\" --grep

for i in $(cat -n ~/tmp/cherrypick_880300 | sort -n -r | awk '{ print $2;}')
do
    echo "cherry picking $i"
    #git cherry-pick $i

    if [ "$?" -ne 0 ]
    then
        echo "git cherry-pick $i returns with error"
        exit 1
    fi
done

