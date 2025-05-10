FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Update und Installation der notwendigen Pakete (inkl. curl und gnupg)
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    openssh-server \
    supervisor \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    python3-pip
# Mosquitto Repository
RUN curl -sL https://repo.mosquitto.org/debian/mosquitto-repo.gpg.key | apt-key add - && \
    echo "deb http://repo.mosquitto.org/debian buster main" > /etc/apt/sources.list.d/mosquitto.list

# Grafana Repository
RUN curl -sL https://packages.grafana.com/gpg.key | apt-key add - && \
    echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list

# InfluxData Repository (für influxdb, telegraf und chronograf) hinzufügen
RUN curl -sL https://repos.influxdata.com/influxdb.key | apt-key add - && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D8FF8E1F7DF8B07E && \
    echo "deb https://repos.influxdata.com/ubuntu focal stable" > /etc/apt/sources.list.d/influxdb.list


# Aktualisieren und Installation der Zielpakete
RUN apt-get update && apt-get install -y \
    mosquitto \
    influxdb \
    telegraf \
    chronograf \
    grafana


# Update, Upgrade und Installation von Grundpaketen
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server \
    supervisor \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    python3-pip

# Repositories hinzufügen
## Mosquitto: Repository-Schlüssel und Repository (Debian Buster)
RUN curl -sL https://repo.mosquitto.org/debian/mosquitto-repo.gpg.key | apt-key add - && \
    echo "deb http://repo.mosquitto.org/debian buster main" > /etc/apt/sources.list.d/mosquitto.list

## Grafana: Repository-Schlüssel und Repository
RUN curl -sL https://packages.grafana.com/gpg.key | apt-key add - && \
    echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list

# Erneut aktualisieren und alle Zielpakete installieren
RUN apt-get update && apt-get install -y \
    mosquitto \
    influxdb \
    telegraf \
    chronograf \
    grafana

# (Optional) Verzeichnisbereinigung – in einem frischen Container meist nicht nötig
RUN rm -rf /etc/mosquitto /var/lib/mosquitto /var/log/mosquitto && \
    rm -rf /etc/influxdb /var/lib/influxdb /var/log/influxdb && \
    rm -rf /etc/telegraf /var/lib/telegraf /var/log/telegraf && \
    rm -rf /etc/chronograf /var/lib/chronograf /var/log/chronograf && \
    rm -rf /etc/grafana /var/lib/grafana /var/log/grafana

# -----------------------------
# Konfiguration Mosquitto
# -----------------------------
# Erstelle /run/mosquitto mit den richtigen Rechten
RUN mkdir -p /run/mosquitto && chown mosquitto:mosquitto /run/mosquitto && chmod 0750 /run/mosquitto

# Erstelle Logverzeichnis und Logdatei (wie in /home/siddy/mqtt/logfile.log)
RUN mkdir -p /home/siddy/mqtt && touch /home/siddy/mqtt/logfile.log && \
    chown mosquitto:mosquitto /home/siddy/mqtt/logfile.log && chmod 0644 /home/siddy/mqtt/logfile.log

# Stelle sicher, dass das Konfigurationsverzeichnis existiert
RUN mkdir -p /etc/mosquitto/conf.d

# Mosquitto-Konfiguration (entspricht Ansible)
#!/usr/bin/env sh
RUN cat <<EOF >> /etc/mosquitto/mosquitto.conf
pid_file /run/mosquitto/mosquitto.pid
persistence true
persistence_location /var/lib/mosquitto/
log_dest file /home/siddy/mqtt/logfile.log
log_type all
log_timestamp true
log_timestamp_format %Y-%m-%dT%H:%M:%S
include_dir /etc/mosquitto/conf.d
password_file /etc/mosquitto/pw.passwd
allow_anonymous false
listener 1883
max_connections -1
EOF

# Erstelle das Mosquitto-Passwortfile (Benutzer "shelly" mit Passwort "pw123456")
RUN mosquitto_passwd -b -c /etc/mosquitto/pw.passwd shelly pw123456 && \
    chown mosquitto:mosquitto /etc/mosquitto/pw.passwd && chmod 0600 /etc/mosquitto/pw.passwd

# -----------------------------
# Konfiguration InfluxDB
# -----------------------------
# Erstelle benötigte InfluxDB-Verzeichnisse und setze Rechte
RUN mkdir -p /var/lib/influxdb/meta /var/lib/influxdb/data /var/lib/influxdb/wal && \
    chown -R influxdb:influxdb /var/lib/influxdb

# Installiere das Python-Modul influxdb
RUN pip3 install influxdb


# Erstelle das Verzeichnis, falls es noch nicht existiert
RUN mkdir -p /etc/telegraf
# -----------------------------
# Konfiguration Telegraf
# -----------------------------
RUN cat <<EOF >> /etc/telegraf/telegraf.conf
[global_tags]
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = "0s"
  hostname = ""
  omit_hostname = false

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  core_tags = false

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[inputs.diskio]]

[[inputs.kernel]]

[[inputs.mem]]

[[inputs.processes]]

[[inputs.swap]]

[[inputs.system]]

[[inputs.mqtt_consumer]]
  servers = ["tcp://raspberrypi:1883"]
  topics = [
    "shelly_lampe_1/#",
    "shelly_lampe_2/#",
    "shelly_dawid_schreibtisch/#",
    "shelly_spuelmaschine/#",
    "shelly_xavier_schreibtisch/#",
    "shelly_wohnzimmer/#",
    "shelly_dawid_desktop/#"
  ]
  username = "shelly"
  password = "pw123456"
  data_format = "json"

[[outputs.influxdb]]
  urls = ["http://localhost:8086"]
  database = "shelly_mqqt_db"
EOF

# Erstelle das Verzeichnis, falls es noch nicht existiert
RUN mkdir -p /etc/grafana
# -----------------------------
# Konfiguration Grafana
# -----------------------------
RUN cat <<EOF >> /etc/grafana/grafana.ini
#################################### Paths ####################################
[paths]
data = /var/lib/grafana
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins

#################################### Server ####################################
[server]
protocol = http
http_port = 3000
domain = localhost
enforce_domain = false
root_url = %(protocol)s://%(domain)s:%(http_port)s/

#################################### Database ####################################
[database]
type = sqlite3
path = grafana.db

#################################### Auth ######################
[auth.anonymous]
enabled = false
org_name = My castle
org_role = Viewer

[security]
admin_user = admin
admin_password = pw123456

#################################### Datasources ######################
[datasources]
[[datasources.influxdb]]
name = "shelly_mqqt_db"
type = "shelly_mqqt_db"
access = "proxy"
url = "http://localhost:8086"
database = "shelly_mqqt_db"
user = ""
password = ""
isDefault = true
EOF

# -----------------------------
# Konfiguration Chronograf
# -----------------------------
RUN mkdir -p /etc/chronograf && \
    cat <<EOF >> /etc/chronograf/config.toml
[influxdb]
url = "http://localhost:8086"
database = "shelly_mqqt_db"
EOF

# -----------------------------
# Konfiguration SSH
# -----------------------------
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# -----------------------------
# Supervisor-Konfiguration: Alle Dienste starten
# -----------------------------
RUN mkdir -p /etc/supervisor/conf.d && \
    cat <<EOF >> /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true

[program:sshd]
command=/usr/sbin/sshd -D

[program:mosquitto]
command=/usr/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf

[program:influxdb]
command=/usr/bin/influxd

[program:telegraf]
command=/usr/bin/telegraf --config /etc/telegraf/telegraf.conf

[program:grafana]
command=/usr/sbin/grafana-server --config=/etc/grafana/grafana.ini --homepath=/usr/share/grafana

[program:chronograf]
command=/usr/bin/chronograf --config=/etc/chronograf/config.toml
EOF

# Exponierte Ports:
# 22 (SSH), 1883 (Mosquitto), 8086 (InfluxDB), 3000 (Grafana) und 8888 (Chronograf, falls benötigt)
EXPOSE 22 1883 8086 3000 8888

# Starte Supervisor – damit werden alle Dienste automatisch gestartet
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
