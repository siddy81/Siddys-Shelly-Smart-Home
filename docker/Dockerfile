FROM ubuntu:22.04

# Declare environment variables for credentials
ENV ADMIN_USER=root
ENV ADMIN_PASSWORD=root
ENV MOSQUITTO_USER=shelly
ENV MOSQUITTO_PASSWORD=shelly123456
ENV DEBIAN_FRONTEND=noninteractive
# TODO upgrade to 15.8
# Install required packages: openssh-server, sudo
RUN apt-get update && apt-get install -y \
    openssh-server \
    nano \
    sudo && \
    apt-get clean


# --- SSH configuration ---
# Create the directory for the SSH daemon and set the root password
RUN mkdir /var/run/sshd && \
    echo '$ADMIN_USER:$ADMIN_PASSWORD' | chpasswd && \
    sed -i 's/#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22 1883

WORKDIR /tmp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
