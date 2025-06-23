#!/bin/sh

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
mosquitto -c /etc/mosquitto/mosquitto.conf \
  > /var/log/mosquitto/mosquitto.log 2>&1 &



# --- 5) InfluxDB starten + DB anlegen ---
# 1) InfluxDB im Hintergrund starten
influxd -config /etc/influxdb/influxdb.conf \
  > /var/log/influxdb/influxd.log 2>&1 &
INFLUXD_PID=$!

# 2) Warten, bis HTTP-API erreichbar ist
until curl -s http://localhost:8086/ping >/dev/null; do
  echo "Waiting for InfluxDB to come up…"
  sleep 1
done

# 3) Init-Skript ausführen (erst einmalig, beim ersten Start)
# ... InfluxDB starten und auf API warten (wie gehabt)
if [ -f /var/lib/influxdb/.influxdb_initialized ]; then
    echo "InfluxDB bereits initialisiert – überspringe Import-Schritt."
else
    echo "Importiere Initialisierungs-Skript…"
    influx -precision rfc3339 -import -path /tmp/init-influxdb.iql && \
    touch /var/lib/influxdb/.influxdb_initialized
fi


# --- 6) Telegraf-Config generieren ---
if [ ! -f "$TEMPLATE_CONF" ]; then
  echo "ERROR: Template $TEMPLATE_CONF fehlt!" >&2
  exec tail -f /dev/null
fi
# envsubst ersetzt ${MOSQUITTO_USER} und ${MOSQUITTO_PASSWORD}
envsubst '${MOSQUITTO_USER} ${MOSQUITTO_PASSWORD}' < "$TEMPLATE_CONF" > "$GENERATED_CONF"

# --- 7) Telegraf starten ---
telegraf --config "$GENERATED_CONF" \
  > /var/log/telegraf/telegraf.log 2>&1 &

# --- 8) Grafana starten ---
export GF_SECURITY_ADMIN_USER="$GRAFANA_ADMIN_USER"
export GF_SECURITY_ADMIN_PASSWORD="$GRAFANA_ADMIN_PASSWORD"
mkdir -p /var/log/grafana
grafana-server \
  --homepath=/usr/share/grafana \
  --config=/etc/grafana/grafana.ini \
  >> /var/log/grafana/grafana.log 2>&1 &

# --- 9) Container am Leben halten ---
tail -f /dev/null
