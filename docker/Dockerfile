ENV INFLUXDB_ADMIN_USER=admin
ENV INFLUXDB_ADMIN_PASSWORD=MeinAdminPasswort
FROM ubuntu:latest

# Declare environment variables for credentials
ENV ADMIN_USER=root
ENV ADMIN_PASSWORD=root
ENV MOSQUITTO_USER=shelly
ENV MOSQUITTO_PASSWORD=pw123456
ENV GRAFANA_ADMIN_USER=admin
ENV GRAFANA_ADMIN_PASSWORD=admin
ENV DEBIAN_FRONTEND=noninteractive

# --- Add InfluxData repo & install all packages ---
RUN apt-get update && apt-get install -y gnupg curl && \
    # InfluxData repository
    curl -fsSL https://repos.influxdata.com/influxdata-archive_compat.key \
      | gpg --dearmor -o /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main" \
      > /etc/apt/sources.list.d/influxdata.list && \
    # Grafana repository
    curl -fsSL https://packages.grafana.com/gpg.key \
      | gpg --dearmor -o /usr/share/keyrings/grafana.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" \
      > /etc/apt/sources.list.d/grafana.list

RUN apt-get update && apt-get install -y \
      openssh-server \
      nano sudo less \
      mosquitto \
      mosquitto-clients \
      influxdb \
      telegraf \
      grafana \
      gettext-base && \
    apt-get clean


# --- Prepare directories ---
RUN mkdir -p /run/mosquitto && chown mosquitto:mosquitto /run/mosquitto
RUN mkdir -p /var/log/mosquitto /var/log/influxdb /var/log/telegraf /var/log/grafana && \
    chown mosquitto:mosquitto /var/log/mosquitto && \
    chown influxdb:influxdb /var/log/influxdb && \
    chown telegraf:telegraf /var/log/telegraf && \
    chown grafana:grafana /var/log/grafana

# --- SSH configuration ---
RUN echo "$ADMIN_USER:$ADMIN_PASSWORD" | chpasswd && \
    sed -i 's/#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# --- Copy configs ---
COPY mosquitto/config/mosquitto.conf /etc/mosquitto/mosquitto.conf
COPY telegraf/config/telegraf.conf   /etc/telegraf/telegraf.conf
COPY influxdb/config/influxdb.conf   /etc/influxdb/influxdb.conf
COPY influxdb/config/init-influxdb.iql /tmp/init-influxdb.iql
COPY grafana/provisioning /etc/grafana/provisioning
COPY grafana/dashboards /etc/grafana/dashboards


EXPOSE 22 1883 8083 8086 3000

WORKDIR /tmp



# ganz unten in deinem Dockerfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
