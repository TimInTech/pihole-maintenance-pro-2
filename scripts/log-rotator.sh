#!/usr/bin/env bash
set -Eeuo pipefail

# Rotiert Logdateien von pihole-maintenance-pro ohne logrotate-Abhängigkeit
# Standard: /var/log/pihole-maintenance-pro/pihole-maintenance-pro.log

LOG_FILE="/var/log/pihole-maintenance-pro/pihole-maintenance-pro.log"
MAX_SIZE_BYTES=$((5 * 1024 * 1024)) # 5 MiB
RETENTION=7

rotate() {
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  mv "$LOG_FILE" "${LOG_FILE}.${ts}"
  touch "$LOG_FILE"
}

cleanup_old() {

}

main() {
  [[ -f "$LOG_FILE" ]] || exit 0
  local size
  size=$(stat -c%s "$LOG_FILE")
  if ((size >= MAX_SIZE_BYTES)); then
    rotate
    cleanup_old
  fi
}

main "$@"
