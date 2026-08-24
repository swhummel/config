#!/bin/bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dir1> <dir2>"
    exit 1
fi

DIR1="$1"
DIR2="$2"

if [ ! -d "$DIR1" ]; then
    echo "Error: '$DIR1' is not a directory"
    exit 1
fi

if [ ! -d "$DIR2" ]; then
    echo "Error: '$DIR2' is not a directory"
    exit 1
fi

PLACEHOLDER="/tmp/no_available"

for file1 in "$DIR1"/*; do
    [ -f "$file1" ] || continue

    filename=$(basename "$file1")
    file2="$DIR2/$filename"

    if [ ! -f "$file2" ]; then
        echo "not available" > "$PLACEHOLDER"
        file2="$PLACEHOLDER"
    fi

    vimdiff "$file1" "$file2"
done
