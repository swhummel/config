#!/bin/bash

if [ $# -eq 0 ]; then
    echo "usage: $0 <viewname> - setup view-related shortcuts and/or mountpoints."
else

    newViewName=$1

    # this script expects to run either on DEHETucks or colinux
    if [ "__${HOSTNAME}" == "__DEHETucks" ]; then

        # running on TUX
        TUX_BASED=1

        checkViewDir="/home/swhummel/ccviews/${newViewName}"
        newViewDir="/home/swhummel/ccviews/${newViewName}"

    elif [ "__${HOSTNAME}" == "__colinux" ]; then

        # running on colinux
        TUX_BASED=0

        # since /mnt/view is often not valid at this point,
        # use a different path for checking whether the
        # directory exists
        if [ "__${newViewName}" == "__c00" ]; then
            # colinux-local view
            checkViewDir="/ccviews/${newViewName}"
        else
            # tux-based view
            checkViewDir="/mnt/tucks/ccviews/${newViewName}"
        fi

        newViewDir="/mnt/view"

    else
        echo "unknown HOSTNAME: ${HOSTNAME}; expected <DEHETucks> or <colinux>."
        return
    fi

    if [ -d "$checkViewDir" -o $# -gt 1 -a "$2" = "force" ]; then
        export SHU_CURRENT_VIEWNAME=$newViewName
        export VIEW=$newViewDir
        if [ "$2" != "force" ]; then
            echo "view set to '$SHU_CURRENT_VIEWNAME'"

            if [ ${TUX_BASED} -eq 1 ]; then
                # TUX: a certain view gets distinct bg coloring
                if [ "__${newViewName}" == "__v03" ]; then
                    xtermset -bg grey80
                else
                    xtermset -bg white
                fi
            else
                # colinux: mount master view to either a TUX or a colinux view
                umount /mnt/view
                if [ "__${newViewName}" == "__c00" ]; then
                    mount --bind "/ccviews/${newViewName}" /mnt/view
                else
                    mount "dehetucks:/home/swhummel/ccviews/${newViewName}" /mnt/view
                fi
            fi

            alias pis=" cd ${newViewDir}/PIS"
            alias icd=" cd ${newViewDir}/PIS/source/adapter/icd"
            alias ris=" cd ${newViewDir}/PIS/source/core/ris"
            alias uti=" cd ${newViewDir}/PIS/source/core/util"
            alias rcl=" cd ${newViewDir}/PIS/source/core/routecontrol"
            alias dcl=" cd ${newViewDir}/PIS/source/core/delaycontrol"
            alias drm=" cd ${newViewDir}/PIS/source/core/drm"
            alias ann=" cd ${newViewDir}/PIS/source/core/anncontrol"
            alias ee="  cd ${newViewDir}/PIS/source/core/expressioneval"
            alias hep=" cd ${newViewDir}/PIS/test/integration/hepistestappl"
            alias mod=" cd ${newViewDir}/PIS/test/frame/src"
            alias sim=" cd ${newViewDir}/PIS/test/frame/src/simulators"
            alias app0="cd ${newViewDir}/PIS/test/apps/app0"
            alias app1="cd ${newViewDir}/PIS/test/apps/appCallLevelTests"
            alias app2="cd ${newViewDir}/PIS/test/quick/appTrainRide"
            alias app3="cd ${newViewDir}/PIS/test/apps/appRisBasicTests"
            alias app4="cd ${newViewDir}/PIS/test/apps/appExprTests"
            alias app5="cd ${newViewDir}/PIS/test/apps/appRisMlDecoderTests"
            alias app6="cd ${newViewDir}/PIS/test/apps/appStopOnDemandTests"
            alias app7="cd ${newViewDir}/PIS/test/apps/appExitSideTests"
            alias app8="cd ${newViewDir}/PIS/test/apps/appRisIAT"
            alias cfg=" cd ${newViewDir}/PIS/load/cfg/PISConfig"
            alias bld=" cd ${newViewDir}/PIS/load/bld"
            alias cs="  cd ${newViewDir}/PIS/common/config-spec"
            alias log=" cd ${newViewDir}/TcmsGenSw/lib/helog/src/helogbase"

            cd $newViewDir
        fi

    else
        echo "ERROR: cannot set view to '$1' - view directory '$checkViewDir' not found."
    fi
fi


