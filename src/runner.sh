#!/usr/bin/env bash
set -Eeuo pipefail

# Einfacher Runner. Falls $CRON_SCHEDULE gesetzt ist, starte cron und plane Job ein.
# Andernfalls führe alle 30 Minuten aus.

CMD="/usr/local/bin/pihole_maintenance_pro.sh --all"

setup_cron() {
  local schedule
  schedule=${CRON_SCHEDULE:-}
  if [[ -n "$schedule" ]]; then
    echo "$schedule root $CMD >> /var/log/pihole-maintenance-pro/runner.log 2>&1" >/etc/cron.d/pmp
    chmod 0644 /etc/cron.d/pmp
    crontab /etc/cron.d/pmp
    service cron start
    tail -F /var/log/pihole-maintenance-pro/runner.log &
    # block forever
    sleep infinity
  else
    # Fallback: 30-Minuten-Loop
    while true; do
      echo "[runner] $(date) executing: $CMD"
      eval "$CMD" || true
      sleep 1800
    done
  fi
}

setup_cron
