# Shelly Control Center

This directory contains the Docker configuration for the **Shelly Control Center**. The container bundles OpenSSH, Mosquitto, InfluxDB, Telegraf and Grafana in a single image so you can capture MQTT messages from your Shelly devices and visualise them directly in Grafana.

## Prerequisites

* Docker
* Docker Compose

## Directory Structure

```
.
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
├── influxdb
├── mosquitto
└── telegraf
```

## Configuration

1. Customize your broker settings in `mosquitto/config/mosquitto.conf` if needed.
2. On container startup the credentials are taken from the following environment variables:
    * `MOSQUITTO_USER` / `MOSQUITTO_PASSWORD` – MQTT broker login
    * `ADMIN_USER` / `ADMIN_PASSWORD` – SSH login to the container
    * `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` – Grafana admin account
   Default values are defined in the `Dockerfile` and can be overridden when starting the container.

## Rebuild and Start the Container

Run the commands from this directory:

```bash
docker-compose down
# build and start in one step
docker-compose up -d --build
```

## Access

* SSH: `ssh ADMIN_USER@localhost -p 2222`
* Grafana: <http://localhost:3000>
* MQTT broker: `localhost:1883`

## View Logs

```bash
docker-compose logs -f
```

## Subscribe to All MQTT Messages

```bash
mosquitto_sub -h localhost -p 1883 -u shelly -P shelly123456 -t "#" -v
```

## InfluxDB

```bash
influx -precision rfc3339
USE shelly
SHOW MEASUREMENTS
SELECT * FROM "temperature" LIMIT 10
```
