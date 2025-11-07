FROM eclipse-mosquitto:2.0

USER root

COPY entrypoint.sh /usr/local/bin/mosquitto-entrypoint.sh
RUN chmod 755 /usr/local/bin/mosquitto-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/mosquitto-entrypoint.sh"]
CMD ["mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
