#!/bin/bash
set -e

# --- Pfade ---
MOSQ_CONF_DIR=/etc/mosquitto
PASSWD_FILE=$MOSQ_CONF_DIR/passwd
ACL_FILE=$MOSQ_CONF_DIR/acl
TEMPLATE_CONF=/etc/telegraf/telegraf.conf
GENERATED_CONF=/tmp/telegraf.conf

# --- 0) Mosquitto-Verzeichnis/Rechte ---
mkdir -p "$MOSQ_CONF_DIR"
chown mosquitto:mosquitto "$MOSQ_CONF_DIR"
chmod 750 "$MOSQ_CONF_DIR"

# --- 1) Passwort-File ---
su -s /bin/sh mosquitto -c \
  "mosquitto_passwd -b -c '$PASSWD_FILE' '$MOSQUITTO_USER' '$MOSQUITTO_PASSWORD'"
chown mosquitto:mosquitto "$PASSWD_FILE"
chmod 640 "$PASSWD_FILE"

# --- 2) ACL-File ---
cat <<EOF > "$ACL_FILE"
user $MOSQUITTO_USER
topic readwrite shelly/#
EOF
chown mosquitto:mosquitto "$ACL_FILE"
chmod 640 "$ACL_FILE"

# --- 3) SSH starten ---
service ssh start

# --- 4) Mosquitto starten ---
mosquitto -c /etc/mosquitto/mosquitto.conf &

service telegraf start

# --- 5) InfluxDB starten + DB anlegen ---
service influxdb start
for i in {1..30}; do
  influx -execute "SHOW DATABASES" >/dev/null 2>&1 && break
  sleep 1
done
influx -execute "CREATE DATABASE shelly"

# --- 6) Telegraf-Config generieren ---
if [ ! -f "$TEMPLATE_CONF" ]; then
  echo "ERROR: Template $TEMPLATE_CONF fehlt!" >&2
  exec tail -f /dev/null
fi
# envsubst ersetzt ${MOSQUITTO_USER} und ${MOSQUITTO_PASSWORD}
envsubst '${MOSQUITTO_USER} ${MOSQUITTO_PASSWORD}' < "$TEMPLATE_CONF" > "$GENERATED_CONF"

# --- 7) Telegraf starten ---
telegraf --config "$GENERATED_CONF" &

# --- 8) Container am Leben halten ---
tail -f /dev/null
