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
3. On first start the database `shelly_mqtt_db` is created automatically for Telegraf.

### Default Credentials

The preconfigured logins are:

| Service    | Username | Password      |
|------------|---------|---------------|
| SSH        | `root`  | `root`        |
| Mosquitto  | `shelly` | `pw123456` |
| Grafana    | `admin` | `admin`       |

### Shelly Device Setup

1. Open the web interface of each Shelly device.
2. Navigate to **Internet & Security → MQTT** and enable MQTT.
3. Set the server to the Docker host IP and port `1883`.
4. Enter the Mosquitto credentials from above (`MOSQUITTO_USER` / `MOSQUITTO_PASSWORD`).
5. Choose a unique **Topic** prefix (e.g. `shelly_lamp_1`).
6. Save and reboot the device.

Telegraf subscribes to the configured topic prefixes and forwards all messages to InfluxDB where Grafana can visualise them.

## Rebuild and Start the Container

Run the commands from this directory:

```bash
docker-compose down
# build and start in one step
docker-compose up -d --build
```

## Access

* SSH: `ssh ADMIN_USER@localhost -p 2222`
* Grafana: <http://localhost:3000> (login with `admin` / `admin`)
* MQTT broker: `localhost:1883`

### Grafana Dashboard

Import the dashboard JSON from `grafana/dashboards/shelly_dashboard.json` to get an
overview of temperature and power consumption for your Shelly devices. In
Grafana, navigate to **Dashboards → Import**, upload the JSON file and select the
`InfluxDB` data source when prompted.

### Data Flow

`Shelly device → Mosquitto → Telegraf → InfluxDB → Grafana`

## View Logs

```bash
docker-compose logs -f
```

Service logs are also written inside the container:

```
/var/log/mosquitto/mosquitto.log
/var/log/influxdb/influxd.log
/var/log/telegraf/telegraf.log
/var/log/grafana/grafana.log
```

## Subscribe to All MQTT Messages

```bash
docker exec -it shelly_control_center \
  mosquitto_sub -h localhost -p 1883 \
  -t "#" -u "shelly" -P "pw123456" -v
```

## InfluxDB

```bash
influx -precision rfc3339
USE shelly_mqtt_db
SHOW MEASUREMENTS
SELECT * FROM "temperature" LIMIT 10
```

## Docker Build Notes

If the build fails with `error getting credentials` while pulling the public
base image, your Docker configuration may reference a credential helper that is
not logged in. Because the image is public you can disable BuildKit so that the
helper is skipped:

```bash
DOCKER_BUILDKIT=0 docker-compose build
```

For private registries authenticate first via `docker login`.

