#!/usr/bin/env bash
# pihole-maintenance-pro — Produktionsreifes Wartungsskript
# Autor: Tim
# Lizenz: MIT

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="1.0.0"

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
CONFIG_FILE="/etc/pihole-maintenance-pro/config.cfg"
BACKUP_DIR="/var/backups/pihole"
LOG_DIR="/var/log/pihole-maintenance-pro"
LOG_FILE="$LOG_DIR/pihole-maintenance-pro.log"
LOG_LEVEL="info"
COLOR_OUTPUT=true
NOTIFY_EMAIL=false
EMAIL_TO="root@localhost"
EMAIL_FROM="pihole-maintenance-pro@localhost"
NOTIFY_SLACK=false
SLACK_WEBHOOK_URL=""
DOCKER_MODE="auto"
PIHOLE_CONTAINER_NAME="pihole"
PIHOLE_CMD=""
NICE_LEVEL=0
IONICE_CLASS=2
IONICE_PRIORITY=7
CPU_AFFINITY=""
LOCK_FILE="/var/run/pihole-maintenance-pro.lock"
INCLUDE_ETC_PIHOLE=true
INCLUDE_DNSMASQ=true
RETENTION_DAYS=14

# Log-Level Mapping
level_num() {
  case "$1" in
    debug) echo 0 ;;
    info) echo 1 ;;
    warn) echo 2 ;;
    error) echo 3 ;;
    *) echo 1 ;;
  esac
}
CUR_LEVEL=$(level_num "$LOG_LEVEL")

log() {
  local lvl=$1 msg=$2
  local lvl_num
  lvl_num=$(level_num "$lvl")
  [[ $lvl_num -lt $CUR_LEVEL ]] && return 0
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  local line="[$ts][$lvl] $msg"
  mkdir -p "$LOG_DIR"
  echo "$line" | tee -a "$LOG_FILE" >/dev/null
  if [[ "$COLOR_OUTPUT" == "true" ]]; then
    case "$lvl" in
      debug) echo -e "${CYAN}$line${NC}" ;;
      info) echo -e "${GREEN}$line${NC}" ;;
      warn) echo -e "${YELLOW}$line${NC}" ;;
      error) echo -e "${RED}$line${NC}" ;;
      *) echo "$line" ;;
    esac
  else
    echo "$line"
  fi
}

fail() {
  log error "$1"
  notify_all "Fehler: $1"
  exit 1
}

rotate_if_needed() {
  local max=$((5 * 1024 * 1024))
  if [[ -f "$LOG_FILE" ]] && (($(stat -c%s "$LOG_FILE") >= max)); then
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    mv "$LOG_FILE" "${LOG_FILE}.${ts}" || true
    touch "$LOG_FILE"
  fi
}

load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
  fi
}

is_docker_env() {
  if [[ "$DOCKER_MODE" == "true" ]]; then
    return 0
  fi
  if [[ "$DOCKER_MODE" == "false" ]]; then
    return 1
  fi
  if [[ -f "/.dockerenv" ]]; then
    return 0
  fi
  if grep -qE '/docker/|/containerd/' /proc/1/cgroup 2>/dev/null; then
    return 0
  fi
  return 1
}

pihole_cmd() {
  if [[ -n "$PIHOLE_CMD" ]]; then
    echo "$PIHOLE_CMD"
    return 0
  fi
  if command -v pihole >/dev/null 2>&1; then
    echo "pihole"
    return 0
  fi
  # Docker: via docker exec gegen Container
  if command -v docker >/dev/null 2>&1 && is_docker_env; then
    echo "docker exec -i ${PIHOLE_CONTAINER_NAME} pihole"
    return 0
  fi
  echo "pihole" # Versuch
}

with_resource_limits() {
  local cmd=("$@")
  if [[ -n "$CPU_AFFINITY" ]]; then
    cmd=(taskset -c "$CPU_AFFINITY" "${cmd[@]}")
  fi
  cmd=(ionice -c "$IONICE_CLASS" -n "$IONICE_PRIORITY" nice -n "$NICE_LEVEL" "${cmd[@]}")
  "${cmd[@]}"
}

notify_email() {
  [[ "$NOTIFY_EMAIL" == "true" ]] || return 0
  local subject="[pmp] $1"
  local body=${2:-""}
  if command -v mail >/dev/null 2>&1; then
    printf "%s\n" "$body" | mail -aFrom:"$EMAIL_FROM" -s "$subject" "$EMAIL_TO" || true
  elif command -v sendmail >/dev/null 2>&1; then
    {
      echo "Subject: $subject"
      echo "From: $EMAIL_FROM"
      echo "To: $EMAIL_TO"
      echo
      printf "%s\n" "$body"
    } | sendmail -t || true
  else
    log warn "Kein Mailer installiert. Überspringe E-Mail."
  fi
}

notify_slack() {
  [[ "$NOTIFY_SLACK" == "true" ]] || return 0
  [[ -n "$SLACK_WEBHOOK_URL" ]] || {
    log warn "SLACK_WEBHOOK_URL leer"
    return 0
  }
  local text="$1"
  shift || true
  local payload
  payload=$(jq -nc --arg text "$text" '{text:$text}')
  curl -fsSL -H 'Content-Type: application/json' -d "$payload" "$SLACK_WEBHOOK_URL" || log warn "Slack-Webhook fehlgeschlagen"
}

notify_all() {
  notify_email "$1" "${2:-}"
  notify_slack "$1"
}

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    fail "Root-Rechte benötigt"
  fi
}

lock_acquire() {
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    fail "Skript läuft bereits (Lock: $LOCK_FILE)"
  fi
}

lock_release() {
  # shellcheck disable=SC2317
  flock -u 9
}

# Aktionen
system_update() {
  log info "Führe System-Updates aus"
  if command -v apt-get >/dev/null 2>&1; then
    with_resource_limits apt-get update
    with_resource_limits apt-get -y upgrade
  else
    log warn "Unbekannter Paketmanager. Überspringe System-Updates."
  fi
}

pihole_version_info() {
  local cmd
  cmd=$(pihole_cmd)
  with_resource_limits bash -c "$cmd -v" 2>&1 | sed 's/^/[pihole-v] /'
}

pihole_gravity_update() {
  local cmd
  cmd=$(pihole_cmd)
  log info "Starte Gravity-Update"
  with_resource_limits bash -c "$cmd -g" || fail "Gravity-Update fehlgeschlagen"
  log info "Gravity-Update abgeschlossen"
}

pihole_backup() {
  mkdir -p "$BACKUP_DIR"
  local ts file
  ts=$(date +%Y%m%d-%H%M%S)
  file="$BACKUP_DIR/pihole-backup-${ts}.tar.gz"
  log info "Erstelle Teleporter-Backup: $file"
  local cmd
  cmd=$(pihole_cmd)
  with_resource_limits bash -c "$cmd -a -t" || fail "Teleporter-Backup fehlgeschlagen"
  # Standardablage liegt i. d. R. in /etc/pihole unter dem Namen *.tar.gz -> auffinden und kopieren
  local generated
  generated=$(find /etc/pihole -maxdepth 1 -type f -name '*.tar.gz' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | awk '{print $2}')
  if [[ -n "$generated" && -f "$generated" ]]; then
    cp "$generated" "$file"
    log info "Backup gesichert: $file"
  else
    log warn "Konnte generiertes Teleporter-Archiv nicht finden. Erstelle manuelles Archiv."
    local tmp="/tmp/pmp-backup-${ts}.tar.gz"
    local incl=()
    [[ "$INCLUDE_ETC_PIHOLE" == "true" ]] && incl+=("/etc/pihole")
    [[ "$INCLUDE_DNSMASQ" == "true" ]] && incl+=("/etc/dnsmasq.d")
    tar -czf "$tmp" "${incl[@]}" 2>/dev/null || true
    mv "$tmp" "$file"
  fi
  retention_cleanup "$BACKUP_DIR" "$RETENTION_DAYS"
}

retention_cleanup() {
  local dir=$1 days=$2
  find "$dir" -type f -mtime +"$days" -name 'pihole-backup-*.tar.gz' -print -delete || true
}

health_service() {
  # Prüfe FTL Dienst
  if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
    if ! systemctl is-active --quiet pihole-FTL; then
      log error "pihole-FTL nicht aktiv"
      return 2
    fi
  else
    log debug "systemctl nicht verfügbar oder kein systemd. Überspringe Dienstprüfung."
  fi
  return 0
}

health_dns() {
  # einfache DNS-Abfrage gegen Pi-hole
  if ! command -v dig >/dev/null 2>&1; then
    log warn "dig nicht verfügbar. Überspringe DNS-Test."
    return 0
  fi
  if ! dig +short @127.0.0.1 pi.hole >/dev/null 2>&1; then
    log warn "DNS-Antwort von localhost fehlgeschlagen"
    return 0
  fi
  return 0
}

health_db() {
  local db="/etc/pihole/gravity.db"
  if [[ -f "$db" ]]; then
    local out
    out=$(sqlite3 "$db" 'PRAGMA integrity_check;') || {
      log error "DB Fehler"
      return 2
    }
    if [[ "$out" != "ok" ]]; then
      log error "DB Integrität: $out"
      return 2
    fi
  else
    log warn "gravity.db nicht gefunden"
  fi
  return 0
}

health_all() {
  local rc=0
  health_service || rc=$?
  health_dns || rc=$?
  health_db || rc=$?
  if ((rc != 0)); then
    notify_all "Healthchecks fehlerhaft (RC=$rc)"
  else
    log info "Healthchecks OK"
  fi
  return $rc
}

usage() {
  cat <<'USAGE'
Nutzung: pihole_maintenance_pro.sh [Optionen]

Aktionen:
  --all            Alle Standardaktionen: --update --gravity --backup --health
  --update         System-Updates durchführen
  --gravity        Gravity-Update
  --backup         Pi-hole Backup (Teleporter / Fallback)
  --health         Healthchecks
  --rotate-logs    Interne Logrotation durchführen

Allgemein:
  -c, --config F   Konfigurationsdatei
  --log-level L    debug|info|warn|error
  --no-color       Farbausgabe deaktivieren
  --version        Version ausgeben
  -h, --help       Hilfe
USAGE
}

main() {
  rotate_if_needed
  load_config

  local run_update=false run_gravity=false run_backup=false run_health=false rotate_logs=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        run_update=true
        run_gravity=true
        run_backup=true
        run_health=true
        shift
        ;;
      --update)
        run_update=true
        shift
        ;;
      --gravity)
        run_gravity=true
        shift
        ;;
      --backup)
        run_backup=true
        shift
        ;;
      --health)
        run_health=true
        shift
        ;;
      --rotate-logs)
        rotate_logs=true
        shift
        ;;
      -c | --config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      --log-level)
        LOG_LEVEL="$2"
        shift 2
        ;;
      --no-color)
        COLOR_OUTPUT=false
        shift
        ;;
      --version)
        echo "$VERSION"
        exit 0
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "Unbekannte Option: $1" >&2
        usage
        exit 64
        ;;
    esac
  done

  # Re-apply level mapping after possible change
  CUR_LEVEL=$(level_num "$LOG_LEVEL")

  need_root
  lock_acquire
  trap lock_release EXIT

  log info "pihole-maintenance-pro v$VERSION gestartet"
  pihole_version_info || true

  local rc=0
  if $run_update; then
    system_update || true
  fi
  if $run_gravity; then
    pihole_gravity_update || rc=$?
  fi
  if $run_backup; then
    pihole_backup || rc=$?
  fi
  if $run_health; then
    health_all || rc=$?
  fi
  if $rotate_logs; then
    "$(dirname "$0")/../scripts/log-rotator.sh" || true
  fi

  if ((rc != 0)); then
    log warn "Abgeschlossen mit RC=$rc"
  else
    log info "Abgeschlossen"
  fi
  exit $rc
}

main "$@"
