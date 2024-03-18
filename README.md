# shellySmartHome

## 
```mermaid
graph LR
    Shelly --> Mosquitto
    Mosquitto --> Telegraf
    Telegraf --> InfluxDB
    InfluxDB --> Grafana
    InfluxDB --> Chronograf
```