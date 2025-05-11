#!/bin/bash
set -e

# Pfade
MOSQ_CONF_DIR=/etc/mosquitto
PASSWD_FILE=$MOSQ_CONF_DIR/passwd
ACL_FILE=$MOSQ_CONF_DIR/acl

# 1) Passwortdatei erzeugen
mosquitto_passwd -b -c "$PASSWD_FILE" "$MOSQUITTO_USER" "$MOSQUITTO_PASSWORD"

# 2) ACL anlegen: nur Topics shelly/#
cat <<EOF > "$ACL_FILE"
user $MOSQUITTO_USER
topic readwrite shelly/#
EOF

# 3) Dienste starten
service ssh start
#service mosquitto start
mosquitto -d -c /etc/mosquitto/mosquitto.conf

# 4) Log-Ausgabe am Leben halten
tail -f /dev/null
