# parameters: repository build_conf ...

REPOSITORY_TYPE=`echo $0 | sed 's/^.*_\([^.]*\)\.sh/\1/'`

BASE_PATH=/home/mdittric
MAKE_CMD="make"
#REPOSITORY_TYPE=git

if [ $# -lt 1 ]
then
  echo "usage: `basename $0` <repository_tag> [<config>] ..."
  exit 1
fi

REPOSITORY_TAG=$1
shift
REPOSITORY_SUB_PATH=${REPOSITORY_TYPE}/${REPOSITORY_TAG}
REPOSITORY_DIR=${BASE_PATH}/${REPOSITORY_SUB_PATH}/vobs/
BUILD_DIR=${BASE_PATH}/build/${REPOSITORY_SUB_PATH}

#BUILD_CONFIGS=${@:-pismdt[LS]* p[co]smdtSTD}
#BUILD_CONFIGS=${@:-[prs]*mdt* vsrv* ASV* PDU*}
#BUILD_CONFIGS=${@:-[prs]*mdt*STD pismdtLNVG vsrv*STD ASV_BUILD[CS]* PDU* mcg*}
BUILD_CONFIGS=${@:-[prs]*mdt*STD vsrv*STD ASV_BUILD[CS]* PDU* mc?mdt* mcgasv*}

# e.g. call with:
# build_all_git.sh do2010_dev {pis,vsrvinter,webhmi,ASV}*DO2010*
# build_all_git.sh do2010_dev ; build_all_git.sh etp_t3_dev ; build_all_git.sh do2010_dev vsrvinter* ASV_BUILDDO2010_C ; build_all_git.sh do2010_dev mcg*{ETP3,BR490,DO2010,PPCSUP}

if [ ! -d ${REPOSITORY_DIR} ]
then
    echo "repository does not exist: $REPOSITORY_DIR"
    exit 2
fi

if [ ! -d ${BUILD_DIR} ]
then
    echo "build dir does not exist: $BUILD_DIR"
    exit 2
fi

BUILD_LOGFILE=${BASE_PATH}/tmp/${REPOSITORY_TYPE}_build.log
LOGFILE=${BASE_PATH}/tmp/${REPOSITORY_TYPE}_summary.log

rm -f ${BUILD_LOGFILE}
rm -f ${LOGFILE}
rm -f ${BUILD_DIR}/build.log
touch ${BUILD_LOGFILE}

cd ${REPOSITORY_DIR}/tisc_ccu-c/load/bld

echo '#####################################################################################################'
echo "REPOSITORY: $REPOSITORY_DIR"  2>&1 | tee -a ${LOGFILE}
echo "Log to:  ${LOGFILE}"

for CONFIG in ${BUILD_CONFIGS}
do
    DLU_OPT=""
    echo "${CONFIG}" | egrep 'asv|ASV|BUILD' && DLU_OPT="-d"
    #BUILD_CMD="./multibuild.sh -n ${CONFIG} -L none -E -R ${DLU_OPT}" # whithout unittest
    BUILD_CMD="./multibuild.sh -n ${CONFIG} -L none -E ${DLU_OPT}"
    PRJ_UPPER=`echo $PRJ | gawk '{print toupper($0);}'`
    echo '######################################' 2>&1 | tee -a ${LOGFILE}
    date 2>&1 | tee -a ${LOGFILE}
    echo "Build ${CONFIG} in: ${BUILD_DIR}" 2>&1 | tee -a ${LOGFILE}
    echo "${BUILD_CMD}"
    echo '######################################' 2>&1 | tee -a ${LOGFILE}

    tail --lines=1 -f ${BUILD_LOGFILE} | gawk '/^--- make/{if(n>0){printf("\n");}print;n=1;}/^[[]/{percent=$0;sub("[]].*$","]",percent);if(prevPercent!=percent){printf("\r%s", percent);prevPercent=percent}}END{printf("\n")}' &
    TAIL_PID=`jobs -p`
    ${BUILD_CMD} 2>&1 >> ${BUILD_LOGFILE}
    EXIT_CODE=$?
    kill ${TAIL_PID} 2>/dev/null
#    ${BUILD_CMD} 2>&1 | tee ${BUILD_LOGFILE} | gawk '/^[[]/{if(percent!=$2){print;percent=$2}}' # | tr '\n' '\r'
    echo "./multibuild.sh ${CONFIG} returns: ${EXIT_CODE}" 2>&1 | tee -a ${LOGFILE}
    date 2>&1 | tee -a ${LOGFILE}

# CCUC
#    cmake -DTISC_PROJECT=${PRJ_UPPER} -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_DIR}/${PLATFORM_TARGET} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ${REPOSITORY_DIR}/tisc_ccu-c/load/bld/
# PIS
#    cmake -DTISC_PROJECT=${PRJ_UPPER} -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_DIR}/MDT.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ${REPOSITORY_DIR}/PIS/test/bld/
# VSRV
#    cmake -DTISC_PROJECT=${PRJ_UPPER} -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_DIR}/MDT.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ${REPOSITORY_DIR}/tisc_vsrv/bld/
# visuXml2Dot
# cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=/opt/projects/TCMS_HE_Platform/1.5.1.0/MDT.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ~/git/do2010_dev/vobs/tisc_webhmi/src/scxmlDocBuilder/visuXml2Dot/bld/
done

echo '######################################'  2>&1 | tee -a ${LOGFILE}
echo "summary:  ${LOGFILE}"
echo "buld log: ${BUILD_LOGFILE}"
egrep --col '^|^Build.*in: |.* returns: [^0].*|/[^/]*/(load|dbg)|[a-z0-9_]*\.cs' ${LOGFILE}

cd -
