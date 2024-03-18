# shellySmartHome

## 
```mermaid
graph LR
    Shelly 1 --> Mosquitto
    Shelly 2 --> Mosquitto
    Shelly n --> Mosquitto
    Mosquitto --> Telegraf
    Telegraf --> InfluxDB
    InfluxDB --> Grafana
    InfluxDB --> Chronograf
```