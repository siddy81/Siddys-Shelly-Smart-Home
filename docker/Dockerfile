FROM ubuntu:22.04

# Declare environment variables for credentials
ENV ADMIN_USER=root
ENV ADMIN_PASSWORD=root
ENV MOSQUITTO_USER=shelly
ENV MOSQUITTO_PASSWORD=shelly123456
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    nano \
    sudo \
    mosquitto \
    mosquitto-clients && \
    apt-get clean

RUN mkdir -p /run/mosquitto && chown mosquitto:mosquitto /run/mosquitto


# SSH-Daemon einrichten
RUN mkdir /var/run/sshd && \
    echo "$ADMIN_USER:$ADMIN_PASSWORD" | chpasswd && \
    sed -i 's/#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Mosquitto-Konfiguration kopieren
COPY mosquitto/config/mosquitto.conf /etc/mosquitto/mosquitto.conf

EXPOSE 22 1883

WORKDIR /tmp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
