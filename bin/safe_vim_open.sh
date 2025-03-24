#!/bin/bash

# Überprüfen, ob eine Datei angegeben wurde
if [ $# -eq 0 ]; then
    echo "Bitte geben Sie den Pfad zur Datei an."
    exit 1
fi

FILE=$(realpath "$1")
SWAP_FILE=".$(basename "$FILE").swp"
SWAP_DIR="$(dirname "$FILE")"

# Überprüfen, ob die Swap-Datei existiert
if [ -e "$SWAP_DIR/$SWAP_FILE" ]; then
    echo "Die Datei '$FILE' scheint bereits in einer anderen vim-Instanz geöffnet zu sein."
    echo "Wenn Sie sicher sind, dass das nicht der Fall ist, können Sie es mit vim noch öffnen."
    exit 1
else
    # Datei mit vim öffnen
    vim "$FILE"
fi

