#!/bin/sh
set -eu

PASSFILE="/mosquitto/config/passwordfile"
TMPPASS="$(mktemp)"

: "${MQTT_USERNAME:=shelly}"
: "${MQTT_PASSWORD:=123456}"
export MQTT_USERNAME MQTT_PASSWORD

trap 'rm -f "$TMPPASS"' EXIT INT TERM

mosquitto_passwd -b -c "$TMPPASS" "$MQTT_USERNAME" "$MQTT_PASSWORD"

mv "$TMPPASS" "$PASSFILE"
trap - EXIT INT TERM
chmod 600 "$PASSFILE" || true

exec mosquitto -c /mosquitto/config/mosquitto.conf
