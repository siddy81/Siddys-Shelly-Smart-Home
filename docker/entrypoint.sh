#!/bin/sh

# --- Pfade ---
MOSQ_CONF_DIR=/etc/mosquitto
PASSWD_FILE=$MOSQ_CONF_DIR/passwd
ACL_FILE=$MOSQ_CONF_DIR/acl
TEMPLATE_CONF=/etc/telegraf/telegraf.conf
GENERATED_CONF=/tmp/telegraf.conf

# --- 0) Create config & log directories with correct permissions ---
mkdir -p "$MOSQ_CONF_DIR" /var/log/mosquitto /var/log/influxdb /var/log/telegraf /var/log/grafana
chown mosquitto:mosquitto "$MOSQ_CONF_DIR" /var/log/mosquitto
chmod 750 "$MOSQ_CONF_DIR" /var/log/mosquitto

# Set other log directory owners
chown influxdb:influxdb /var/log/influxdb
chown telegraf:telegraf /var/log/telegraf
chown grafana:grafana /var/log/grafana

chmod 750 /var/log/influxdb /var/log/telegraf /var/log/grafana

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

    echo "Initialisiere InfluxDB…"
    influx -execute "CREATE USER ${INFLUXDB_ADMIN_USER} WITH PASSWORD '${INFLUXDB_ADMIN_PASSWORD}' WITH ALL PRIVILEGES" && \
    influx -username ${INFLUXDB_ADMIN_USER} -password ${INFLUXDB_ADMIN_PASSWORD} -execute "CREATE DATABASE \"shelly_mqtt_db\"" && \
    influx -username ${INFLUXDB_ADMIN_USER} -password ${INFLUXDB_ADMIN_PASSWORD} -execute "CREATE USER telegraf WITH PASSWORD 'TelegrafPasswort'" && \
    influx -username ${INFLUXDB_ADMIN_USER} -password ${INFLUXDB_ADMIN_PASSWORD} -execute "GRANT ALL ON \"shelly_mqtt_db\" TO telegraf" && \

# --- 4) Mosquitto starten as mosquitto user ---
su -s /bin/sh mosquitto -c \
  "mosquitto -c /etc/mosquitto/mosquitto.conf \
    >> /var/log/mosquitto/mosquitto.log 2>&1 &"

# --- 5) InfluxDB starten + DB anlegen ---
# 5.1) Start InfluxDB in background
influxd -config /etc/influxdb/influxdb.conf \
  >> /var/log/influxdb/influxd.log 2>&1 &

INFLUXD_PID=$!

# 5.2) Wait for HTTP API
until curl -s http://localhost:8086/ping >/dev/null; do
  echo "Waiting for InfluxDB to come up…"
  sleep 1
done

# 5.3) Initial import (if not yet done)
if [ -f /var/lib/influxdb/.influxdb_initialized ]; then
    echo "InfluxDB already initialized – skipping import."
else
    echo "Importing initial script…"
    influx -precision rfc3339 -import -path /tmp/init-influxdb.iql && \
    touch /var/lib/influxdb/.influxdb_initialized
fi

# --- 6) Telegraf-Config generieren ---
if [ ! -f "$TEMPLATE_CONF" ]; then
  echo "ERROR: Template $TEMPLATE_CONF not found!" >&2
  exec tail -f /dev/null
fi
envsubst '${MOSQUITTO_USER} ${MOSQUITTO_PASSWORD}' < "$TEMPLATE_CONF" > "$GENERATED_CONF"

# --- 7) Telegraf starten ---
su -s /bin/sh telegraf -c \
  "telegraf --config '$GENERATED_CONF' \
    >> /var/log/telegraf/telegraf.log 2>&1 &"

# --- 8) Grafana starten ---
export GF_SECURITY_ADMIN_USER="$GRAFANA_ADMIN_USER"
export GF_SECURITY_ADMIN_PASSWORD="$GRAFANA_ADMIN_PASSWORD"
su -s /bin/sh grafana -c \
  "grafana-server \
    --homepath=/usr/share/grafana \
    --config=/etc/grafana/grafana.ini \
    >> /var/log/grafana/grafana.log 2>&1 &"

# --- 9) Container am Leben halten ---
tail -f /dev/null
