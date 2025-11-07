#!/bin/sh
set -eu

PASSFILE="/mosquitto/config/passwordfile"
TMPPASS="$(mktemp)"

: "${MQTT_USERNAME:=shelly}"
: "${MQTT_PASSWORD:=123456}"

trap 'rm -f "$TMPPASS"' EXIT INT TERM

mosquitto_passwd -b -c "$TMPPASS" "$MQTT_USERNAME" "$MQTT_PASSWORD"

mv "$TMPPASS" "$PASSFILE"
trap - EXIT INT TERM
chmod 600 "$PASSFILE" || true
chown mosquitto:mosquitto "$PASSFILE" || true

if command -v su-exec >/dev/null 2>&1; then
  exec su-exec mosquitto mosquitto -c /mosquitto/config/mosquitto.conf
elif command -v gosu >/dev/null 2>&1; then
  exec gosu mosquitto mosquitto -c /mosquitto/config/mosquitto.conf
else
  exec mosquitto -c /mosquitto/config/mosquitto.conf
fi
