# Shelly Smart Home Monitoring – Docker Setup

Dieses Verzeichnis enthält die vollständige Docker-Umgebung für das Shelly Smart Home Monitoring. Sie besteht aus vier eigenständigen Containern, die per MQTT Daten austauschen und die Messwerte in Echtzeit visualisieren.

## Container

| Dienst     | Zweck                                   | Wichtige Ports |
|------------|-----------------------------------------|----------------|
| Mosquitto  | MQTT-Broker für alle Shelly-Geräte      | 1883           |
| Telegraf   | MQTT-Subscriber und Forwarder zu Influx | –              |
| InfluxDB   | Zeitreihendatenbank                     | 8086           |
| Grafana    | Dashboard & Visualisierung              | 12345          |

Alle Dienste teilen sich das interne Docker-Netzwerk, wodurch der Datenfluss Shelly → Mosquitto → Telegraf → InfluxDB → Grafana ohne zusätzliche Konfiguration funktioniert.

## Schnellstart

```bash
cd docker
cp example.env .env  # enthält die Standard-Zugangsdaten (MQTT & Grafana)
docker compose up -d
```

Nach dem Start steht das Dashboard unter [http://localhost:12345](http://localhost:12345) zur Verfügung. Der anonyme Lesezugriff ist bereits aktiviert, das Admin-Passwort kann über `GRAFANA_ADMIN_PASSWORD` angepasst werden.

## Konfiguration

- **Mosquitto**: Die Broker-Konfiguration liegt unter `mosquitto/config/mosquitto.conf`. Anonyme Verbindungen sind deaktiviert; das Passwortfile `mosquitto/config/passwordfile` enthält den initialen Benutzer `shelly` mit dem Passwort `123456`.
- **Telegraf**: Die Datei `telegraf/telegraf.conf` definiert, welche MQTT-Themen abonniert und wie sie nach InfluxDB geschrieben werden. Die Umgebungsvariablen `MQTT_USERNAME` und `MQTT_PASSWORD` werden automatisch ausgewertet.
- **InfluxDB**: Persistente Daten liegen im Volume `influxdb/data`. Standardmäßig wird die Datenbank `shelly` ohne Authentifizierung angelegt.
- **Grafana**: Dashboards und Datenquellen werden per Provisioning aus `grafana/` geladen. Das bereitgestellte Dashboard heißt **Shelly Smart Home Overview**.

## Nützliche Befehle

```bash
# Container-Logs verfolgen
docker compose logs -f

# MQTT-Test-Nachricht senden
mosquitto_pub -h localhost -p 1883 -t "shellies/test-device/relay/0/power" -m "42"

# Letzte Power-Werte direkt aus InfluxDB lesen
docker compose exec influxdb influx -database shelly -execute "SELECT * FROM shelly_measurements LIMIT 5"
```

Viel Spaß beim Monitoring Ihres Shelly Smart Homes!
