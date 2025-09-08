#!/usr/bin/env bash
set -Eeuo pipefail

# Installationsskript für pihole-maintenance-pro
# - kopiert Hauptskript nach /usr/local/bin
# - legt Config & Verzeichnisse an
# - optional: Cron-Einträge und Logrotate

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo -e "${RED}Dieses Skript muss als root ausgeführt werden.${NC}" >&2
    exit 1
  fi
}

main() {
  require_root
  echo -e "${BLUE}Installing pihole-maintenance-pro...${NC}"

  local repo_root
  repo_root=$(pwd)

  # Ziele
  local bin_target="/usr/local/bin/pihole_maintenance_pro.sh"
  local runner_target="/usr/local/bin/runner.sh"
  local etc_dir="/etc/pihole-maintenance-pro"
  local cfg_target="$etc_dir/config.cfg"
  local log_dir="/var/log/pihole-maintenance-pro"
  local backup_dir="/var/backups/pihole"

  mkdir -p "$etc_dir" "$log_dir" "$backup_dir"

  # Kopieren
  if [[ -f "$repo_root/src/pihole_maintenance_pro.sh" ]]; then
    install -m 0755 "$repo_root/src/pihole_maintenance_pro.sh" "$bin_target"
  else
    echo -e "${RED}src/pihole_maintenance_pro.sh nicht gefunden.${NC}" >&2
    exit 2
  fi

  if [[ -f "$repo_root/src/runner.sh" ]]; then
    install -m 0755 "$repo_root/src/runner.sh" "$runner_target"
  fi

  if [[ -f "$repo_root/config.example" ]]; then
    cp -n "$repo_root/config.example" "$cfg_target"
  fi

  # Optional: Logrotate Helper installieren
  if [[ -f "$repo_root/scripts/log-rotator.sh" ]]; then
    install -m 0755 "$repo_root/scripts/log-rotator.sh" \
      "/usr/local/bin/pmp-log-rotator"
  fi

  echo -e "${GREEN}Installiert:${NC} $bin_target"
  echo -e "${GREEN}Config:${NC} $cfg_target"
  echo -e "${GREEN}Logs:${NC} $log_dir"
  echo -e "${GREEN}Backups:${NC} $backup_dir"

  # Hinweise
  echo -e "${YELLOW}Passe die Konfiguration an:${NC} $cfg_target"
  echo -e "${YELLOW}Beispiel-Cronjobs:${NC} examples/cron_job.example"
}

main "$@"
