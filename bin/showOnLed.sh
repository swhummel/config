#! /bin/bash

UTILPATH=/home/pi/work/rpi-rgb-led-matrix/utils
COLS=64
ROWS=32

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

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            printUsage
            exit 0
            ;;
        -p)
            sudo ${UTILPATH}/led-image-viewer ${FIX_PARAMETERS} -C $2
            shift # past argument
            shift # past value
            exit 0
            ;;
        -t)
            sudo ${UTILPATH}/text-scroller ${FIX_PARAMETERS} -C 255,0,0 -f ${UTILPATH}/../fonts/9x18B.bdf -y 7 "$2"
            shift # past argument
            shift # past value
            exit 0
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

printError $@
exit 1

