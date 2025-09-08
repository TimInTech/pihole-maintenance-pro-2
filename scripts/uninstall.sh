#!/usr/bin/env bash
set -Eeuo pipefail

# Entfernt alle installierten Artefakte

require_root() { if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "root benötigt" >&2
  exit 1
fi; }

main() {
  require_root
  rm -f /usr/local/bin/pihole_maintenance_pro.sh /usr/local/bin/pmp /usr/local/bin/runner.sh /usr/local/bin/pmp-log-rotator || true
  echo "Entfernt Binärdateien"
  # Configs & Logs optional
  echo "Optional: rm -rf /etc/pihole-maintenance-pro /var/log/pihole-maintenance-pro /var/backups/pihole"
}

main "$@"
