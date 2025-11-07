FROM eclipse-mosquitto:2.0

USER root

COPY entrypoint.sh /mosquitto-entrypoint.sh
RUN chmod 755 /mosquitto-entrypoint.sh

ENTRYPOINT ["/mosquitto-entrypoint.sh"]
CMD ["mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
