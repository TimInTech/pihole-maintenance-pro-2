# Troubleshooting

## Häufige Probleme

### `pihole` Befehl nicht gefunden
- Bare-Metal: Pi-hole nicht installiert oder kein `PATH`. Prüfe `which pihole`.
- Docker: Nutze `docker exec <container> pihole ...`. Setze `PIHOLE_CONTAINER_NAME`.

### `pihole-FTL` nicht aktiv
- Bare-Metal: `systemctl status pihole-FTL` prüfen, ggf. `sudo systemctl restart pihole-FTL`.
- Docker: `docker logs <pihole>` prüfen.

### Slack-Webhook schlägt fehl
- Prüfe `SLACK_WEBHOOK_URL` und ausgehende Verbindung.
- Proxy/Firewall beachten.

### Teleporter-Backup fehlt
- CLI `pihole -a -t` erfordert ausreichende Rechte. Mit `sudo` ausführen.

### Datenbank-Integrität
- Befehl: `sqlite3 /etc/pihole/gravity.db 'PRAGMA integrity_check;'` soll `ok` liefern.

## Diagnosebefehle
```bash
which pihole
pihole -v
systemctl status pihole-FTL
journalctl -u pihole-FTL --no-pager -n 200
sqlite3 /etc/pihole/gravity.db 'PRAGMA integrity_check;'
```
