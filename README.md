# Shelly Smart Home Monitoring

Dieses Projekt stellt eine vollständig containerisierte Referenzarchitektur bereit, um Sensordaten von Shelly-Geräten zentral zu sammeln, zu speichern und in Echtzeit zu visualisieren. Die Kommunikation zwischen allen Komponenten erfolgt über MQTT.

## Architekturüberblick

```text
Shelly-Gerät ─▶ Mosquitto (MQTT Broker) ─▶ Telegraf ─▶ InfluxDB ─▶ Grafana
```

- **Mosquitto** empfängt alle MQTT-Nachrichten der Shelly-Geräte.
- **Telegraf** abonniert die relevanten Topics, normalisiert die Daten und schreibt sie in die Zeitreihendatenbank.
- **InfluxDB** speichert Stromverbrauch, Zustände sowie Temperatur- und Feuchtigkeitswerte.
- **Grafana** visualisiert die Messwerte in einem bereitgestellten Dashboard, das öffentlich unter Port `12345` erreichbar ist.

Alle Services laufen in Docker-Containern und können über `docker compose` gemeinsam verwaltet werden.

## Voraussetzungen

- Docker 20.x oder neuer
- Docker Compose Plugin (`docker compose`)
- Shelly-Geräte, die ihre Messwerte per MQTT publizieren

## Installation & Betrieb

1. Repository klonen und ins Docker-Verzeichnis wechseln:
   ```bash
   git clone https://github.com/<ihr-account>/Siddys-Shelly-Smart-Home.git
   cd Siddys-Shelly-Smart-Home/docker
   ```
2. `.env` aus dem Template erstellen und bei Bedarf Zugangsdaten anpassen:
   ```bash
   cp example.env .env
   # Werte für MQTT_USERNAME, MQTT_PASSWORD und GRAFANA_ADMIN_PASSWORD setzen
   ```
3. Stack starten:
   ```bash
   docker compose up -d
   ```
   Beim Start erzeugt der Mosquitto-Container automatisch eine Passwortdatei in `mosquitto/config/passwordfile` auf Basis der
   gesetzten Variablen `MQTT_USERNAME` und `MQTT_PASSWORD`.
4. Grafana-Dashboard öffnen: <http://localhost:12345>

### MQTT-Anbindung der Shelly-Geräte

- Broker-Adresse: IP des Docker-Hosts, Port `1883`
- Topics: Das Telegraf-Setup überwacht standardmäßig `shellies/#`. Eigene Geräte können ohne zusätzliche Konfiguration publizieren.
- Standard-Zugangsdaten: Benutzername `shelly`, Passwort `123456`. Die Werte lassen sich über `.env` (Variablen `MQTT_USERNAME` und `MQTT_PASSWORD`) anpassen.
- Shelly-Geräte müssen dieselben Zugangsdaten verwenden (Menü: **Einstellungen → Internet & Sicherheit → Erweitert → MQTT**).

## Datenmodell

Telegraf erzeugt zwei Messungen in InfluxDB:

- `shelly_measurements`: numerische Werte (Leistung, Energie, Temperatur, Luftfeuchtigkeit, Batteriestände). Die Felder werden als `reading` gespeichert und können über die Tags `device` und `topic` gefiltert werden.
- `shelly_states`: textuelle Zustände (Tür-/Fenstersensoren, Eingangsereignisse). Die aktuelle Ausprägung liegt im Feld `state`.

Diese Struktur ermöglicht flexible Auswertungen in Grafana. Das bereitgestellte Dashboard enthält u. a. aktuelle Leistungswerte, Zeitreihen sowie eine Status-Tabelle für Tür- und Fensterkontakte.

## Nützliche Kommandos

```bash
# Status aller Container prüfen
docker compose ps

# Logs eines Dienstes anzeigen (z. B. Telegraf)
docker compose logs -f telegraf

# MQTT-Nachrichten live beobachten
mosquitto_sub -h localhost -p 1883 -t "shellies/#" -v

# Testwert publizieren
mosquitto_pub -h localhost -p 1883 -t "shellies/test/relay/0/power" -m "75"

# Direktabfrage in InfluxDB
docker compose exec influxdb influx -database shelly -execute "SELECT * FROM shelly_measurements LIMIT 5"
```

## Sicherheitshinweise

- Ersetzen Sie die mitgelieferten Standardpasswörter (`shelly` / `123456`) für den MQTT-Broker sowie die Grafana-Admin-Zugangsdaten.
- Aktivieren Sie HTTPS vor dem Exponieren des Dashboards im öffentlichen Internet.
- Beschränken Sie die Netzwerkanbindung der Shelly-Geräte auf das nötige Minimum (Firewall/VLAN).

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Beiträge und Erweiterungen sind willkommen.
