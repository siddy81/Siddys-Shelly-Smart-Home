# Shelly Control Center

This repository contains the Docker configuration for the **Shelly Control Center** container, which combines OpenSSH and the Mosquitto MQTT broker.

## Prerequisites

* Docker
* Docker Compose

## Directory Structure

```
.
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
└── mosquitto
    └── config
        └── mosquitto.conf
```

## Configuration

1. Customize your broker settings in `mosquitto/config/mosquitto.conf`.
2. On container startup, the user and ACL are generated automatically from the environment variables:

    * User: `MOSQUITTO_USER`
    * Password: `MOSQUITTO_PASSWORD`
3. SSH access is provided by `ADMIN_USER` and `ADMIN_PASSWORD`.

## Rebuild and Start the Container

Run the following commands from the project root directory:

```bash
# Stop and remove old containers and networks
docker-compose down

# Build the Docker image
docker-compose build

# Start containers in detached mode
docker-compose up -d

# Or combine build and start
docker-compose up -d --build
```

## View Logs

To verify that both SSH and Mosquitto started correctly:

```bash
docker-compose logs -f
```

## Subscribe to All MQTT Messages

To view all incoming MQTT messages (from any topic) live, use the `mosquitto_sub` CLI tool:

```bash
mosquitto_sub -h localhost -p 1883 -u shelly -P shelly123456 -t "#" -v
```

Flags explanation:

* `-h localhost`: MQTT broker address inside the container
* `-p 1883`: Default MQTT port
* `-u shelly`: Username
* `-P shelly123456`: Password
* `-t "#"`: Wildcard topic to receive all topics
* `-v`: Verbose mode, shows both topic and payload

All incoming messages will be printed directly to your terminal.
