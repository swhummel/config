#! /bin/bash

LIBBASEPATH=/home/pi/work/rpi-rgb-led-matrix
UTILPATH=${LIBBASEPATH}/utils
EXAMPLEPATH=${LIBBASEPATH}/examples-api-use

COLS=64
ROWS=32
DEFAULTCOLOR='255,255,255'

FIX_PARAMETERS="--led-cols=${COLS} --led-rows=${ROWS} "

function printUsage ()
{
    echo "Sends text or picture to the LED matrix display."
    echo "Its only a forwarder to the utils of the rpi-rgb-led-matrix lib."
    echo "usage: $0 [option]"
    echo "Options:"
    echo "        -p <path to the picture>."
    echo "        -t <text>."
}

function printError ()
{
    echo "Error: $@"
    printUsage
}


COLOR=${DEFAULTCOLOR}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            printUsage
            exit 0
            ;;
        -C)
            COLOR=$2
            shift # past argument
            shift # past value
            ;;
        -p)
            sudo ${UTILPATH}/led-image-viewer ${FIX_PARAMETERS} -C $2
            shift # past argument
            shift # past value
            ;;
        -t)
            #sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/9x18B.bdf -y 7 "$2"
            sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/10x20.bdf -y 7 "$2"
            #sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/8x13O.bdf -y 7 "$2"
            #sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/helvR12.bdf -y 7 "$2"
            #sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/clR6x12.bdf -y 7 "$2"
            #sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/texgyre-27.bdf "$2"
            #sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/tom-thumb.bdf -y 7 "$2"
            shift # past argument
            shift # past value
            ;;
        -c)
            sudo ${EXAMPLEPATH}/clock ${FIX_PARAMETERS} -C ${COLOR} -f ${UTILPATH}/../fonts/7x14B.bdf -x 4 -y 9 -d '%H:%M:%S'
            shift # past argument
            ;;
        -*)
            printError $@
            exit 1
            ;;
        *)
            printError $@
            exit 1
            ;;
    esac
done

# fonts:
#   cd lib/fonts
#   ls
#10x20.bdf  5x8.bdf   6x13B.bdf  6x9.bdf    7x13O.bdf  8x13B.bdf  9x15B.bdf  9x18.bdf     helvR12.bdf  texgyre-27.bdf
#4x6.bdf    6x10.bdf  6x13.bdf   7x13B.bdf  7x14B.bdf  8x13.bdf   9x15.bdf   AUTHORS      README       tom-thumb.bdf
#5x7.bdf    6x12.bdf  6x13O.bdf  7x13.bdf   7x14.bdf   8x13O.bdf  9x18B.bdf  clR6x12.bdf  README.md
