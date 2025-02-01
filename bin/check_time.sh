#!/bin/bash

# Lokale Zeit abrufen
LOCAL_TIME=$(date +"%Y-%m-%d %H:%M:%S")

# Zeit von einem NTP-Server abrufen
SERVER_TIME=$(curl -s --head time.google.com | grep -i "^date:" | cut -d' ' -f3-)
if [ -z "$SERVER_TIME" ]; then
    notify-send "kein Netz" "curl hat kein Ergebnis geliefert"
    echo "kein Netz"
    exit -1
fi

# Ausgabe der Zeiten
#echo "Lokale Zeit: $LOCAL_TIME"
#echo "Serverzeit: $SERVER_TIME"

# Zeitdifferenz berechnen (in Sekunden)
LOCAL_TIMESTAMP=$(date -d "$LOCAL_TIME" +%s)
SERVER_TIMESTAMP=$(date -d "$SERVER_TIME" +%s)
DIFF=$((LOCAL_TIMESTAMP - SERVER_TIMESTAMP))

# Überprüfen, ob die Zeitabweichung innerhalb von 5 Sekunden liegt
if [ ${DIFF#-} -ge 5 ]; then
    notify-send "Zeitfehler erkannt" "Die Uhrzeit ist nicht korrekt. Abweichung: ${DIFF#-} Sekunden."
    echo "Die Uhrzeit ist nicht korrekt. Abweichung: ${DIFF#-} Sekunden."
fi

# Enable automatic checking per cron:
# crontab -e
# insert: */5 * * * * DISPLAY=:0 /home/swhummel/bin/check_time.sh
