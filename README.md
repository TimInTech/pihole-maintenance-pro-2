# pihole-maintenance-pro

[![CI](https://github.com/TimInTech/pihole-maintenance-pro/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/TimInTech/pihole-maintenance-pro/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-clean-brightgreen.svg)](https://www.shellcheck.net/)

Modulares Wartungsskript mit Backups, Gravity-Updates, Healthchecks, Benachrichtigungen und Logrotation. Läuft auf Bare-Metal und in Docker-Umgebungen, inkl. Unterstützung für `docker exec` gegen einen laufenden Pi-hole-Container.

## Features
- System-Updates, Gravity-Updates, Teleporter-Backups
- Healthchecks (Dienststatus, Datenbank-Integrität, DNS-Tests)
- Benachrichtigungen: E‑Mail und Slack Webhook
- Logging mit Rotation und konfigurierbaren Levels
- Docker-Erkennung und Sidecar-Unterstützung (`docker exec`)
- CLI-Argumente, Konfigurationsdatei, Env-Variablen
- Pi-hole Versionsprüfung (v5+ kompatibel)
- Resource-Limits (nice/ionice/taskset) optional

## Einzeiler-Installation

> Benötigt `curl` und root-Rechte.

```bash
cd ~ && bash -c "$(curl -fsSL https://raw.githubusercontent.com/TimInTech/pihole-maintenance-pro/main/scripts/install.sh)"
```

## Schnelle Nutzung

```bash
# Alles ausführen (Update, Backup, Gravity, Healthchecks)
sudo /usr/local/bin/pihole_maintenance_pro.sh --all

# Nur Backup
sudo /usr/local/bin/pihole_maintenance_pro.sh --backup

# Nur Healthchecks, ausführliches Log
sudo /usr/local/bin/pihole_maintenance_pro.sh --health --log-level debug

# Hilfe
/usr/local/bin/pihole_maintenance_pro.sh --help
```

## Konfiguration

Kopiere `config.example` nach `/etc/pihole-maintenance-pro/config.cfg` und passe Werte an. Alternativ `examples/config.cfg` als Vorlage.

Wichtige Optionen:

* `BACKUP_DIR`, `LOG_DIR`, `LOG_LEVEL`
* `NOTIFY_EMAIL=true|false`, `EMAIL_TO`, `EMAIL_FROM`
* `NOTIFY_SLACK=true|false`, `SLACK_WEBHOOK_URL`
* `DOCKER_MODE=auto|true|false`, `PIHOLE_CONTAINER_NAME=pihole`
* `NICE_LEVEL`, `IONICE_CLASS`, `IONICE_PRIORITY`, `CPU_AFFINITY`

## Cron-Job Beispiele

Siehe `examples/cron_job.example`.

## Screenshots / GIFs

* Troubleshooting und Ausgabe-Beispiele: siehe `docs/`.

## Docker

* Sidecar-Container mit Zeitsteuerung via `CRON_SCHEDULE` oder Host-Cron.
* Siehe `docs/docker-setup.md` und `docker-compose.yml`.

## Troubleshooting

Siehe `docs/troubleshooting.md`.

## Beiträge und Richtlinien

* PRs willkommen. Bitte CI grün halten.
* Linting: `shellcheck`, `shfmt`. Tests: `bats`
* PR-Template: `.github/pull_request_template.md`

## Lizenz

MIT. Siehe `LICENSE`.

