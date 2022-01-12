#!/bin/bash

# remove out files, makefiles and make results below current directory
#
function cleanIt
{
    ITEMLIST=$1
    ITEMDESCR=$2
    COLORPTN=$3
    if [ "$ITEMLIST" == "" ] ; then
        echo "no $ITEMDESCR found."
    else
        echo "found $ITEMDESCR:"
        for item in $ITEMLIST; do 
            echo $item | grep --color $COLORPTN
            echo $item | grep -v $COLORPTN
        done
        echo 
        echo -n "remove them all? [no] "

#        read ANS
#
        #if [ "$ANS" == "yes" ] ; then
            echo "cleaning " $ITEMDESCR "..."
            rm -rf $ITEMLIST
        #fi
    fi
}

if [$# == 1 ]; then
    OUTDIRS=`find $1 -name "out" -type d | grep -v '/raw/'`
    cleanIt "$OUTDIRS" "output directories <ignoring 'raw' out dirs>" "out"

    MAKEFILES=`find $1 -name "Makefile*" -type f | egrep ".*/bld[\.unloaded]*/.*/Makefile|bld[\.unloaded]*/Makefile|hepistestappl/Makefile"`
    cleanIt "$MAKEFILES" "makefiles" "Makefile"

    OUTFILES=`find $1 -name "err.out" -o -name "result.out"`
    cleanIt "$OUTFILES" "output files" "\.out"

    TARGZ=`find $1 -wholename "*/PIS/*/*.tar.gz" -o -wholename "*/TcmsGenSw/Mitrac/*/*.tar.gz"`
    cleanIt "$TARGZ" "tarGz files" "\.tar\.gz"

    # for target output, remove all and re-get from clearcase since
    # some stuff is checked in, some not..  :(
    TARGETOUTDIRS=`find $1 -type d -wholename "*/load/dlu/linux*++"`
    TARGETOUTFILES=`for dd in $TARGETOUTDIRS; do find $dd ; done`
    cleanIt "$TARGETOUTFILES " "target out files" "linux.*\+\+"
    #cleartool update 
else
    OUTDIRS=`find . -name "out" -type d | grep -v '/raw/'`
    cleanIt "$OUTDIRS" "output directories <ignoring 'raw' out dirs>" "out"

    MAKEFILES=`find . -name "Makefile*" -type f | egrep ".*/bld[\.unloaded]*/.*/Makefile|bld[\.unloaded]*/Makefile|hepistestappl/Makefile"`
    cleanIt "$MAKEFILES" "makefiles" "Makefile"

    OUTFILES=`find . -name "err.out" -o -name "result.out"`
    cleanIt "$OUTFILES" "output files" "\.out"

    TARGZ=`find . -wholename "*/PIS/*/*.tar.gz" -o -wholename "*/TcmsGenSw/Mitrac/*/*.tar.gz"`
    cleanIt "$TARGZ" "tarGz files" "\.tar\.gz"

    # for target output, remove all and re-get from clearcase since
    # some stuff is checked in, some not..  :(
    TARGETOUTDIRS=`find . -type d -wholename "*/load/dlu/linux*++"`
    TARGETOUTFILES=`for dd in $TARGETOUTDIRS; do find $dd ; done`
    cleanIt "$TARGETOUTFILES " "target out files" "linux.*\+\+"
    #cleartool update 
fi

# cleanup contrib files
#echo "cleaning contrib files"
#rm `find ${VIEW} -type f -name '*contrib*'`

checkView.sh

#cleartool update -ove ./source/visu/src/webui > /dev/null
#cleartool update -ove ./test/data/ > /dev/null
