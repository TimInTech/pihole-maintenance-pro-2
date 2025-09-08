# API-Integration / Benachrichtigungen

## Slack Webhook
- Setze `NOTIFY_SLACK=true` und `SLACK_WEBHOOK_URL` in der Config oder als Env.
- Payload wird als JSON via `curl` gesendet.

## E-Mail
- Setze `NOTIFY_EMAIL=true`, `EMAIL_TO`, `EMAIL_FROM`.
- Versand via `mail`/`sendmail`. Stelle sicher, dass ein MTA konfiguriert ist (z. B. `msmtp`/`postfix`).

## Exit Codes
- `0` Erfolg, `>0` Fehler. Healthchecks melden Fehlercodes >0 für CI.
