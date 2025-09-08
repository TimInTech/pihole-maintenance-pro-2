# Docker Setup

Ziel: Wartung im Sidecar-Container. Das Skript führt `docker exec <PIHOLE_CONTAINER_NAME> pihole ...` aus.

## Voraussetzungen
- Laufender Pi-hole Container, z. B. `pihole`.
- Docker Socket im Sidecar verfügbar: `- /var/run/docker.sock:/var/run/docker.sock:ro`.

## Start mit Compose
```bash
cd /pfad/zu/pihole-maintenance-pro
docker compose up -d --build
```

## Zeitsteuerung

* `CRON_SCHEDULE` setzen (z. B. `*/30 * * * *`).
* Alternativ Host-Cron nutzen und Container einmalig ausführen.

## Env-Variablen

* `PIHOLE_CONTAINER_NAME=pihole`
* `NOTIFY_SLACK`, `SLACK_WEBHOOK_URL`, `NOTIFY_EMAIL`, `EMAIL_TO`, `EMAIL_FROM`

## Logs & Backups

* Logs: `./logs` gemountet auf `/var/log/pihole-maintenance-pro`
* Backups: `./backups` gemountet auf `/var/backups/pihole`

