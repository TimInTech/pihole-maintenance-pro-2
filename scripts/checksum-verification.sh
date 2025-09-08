#!/usr/bin/env bash
set -Eeuo pipefail

# Einfache SHA256-Prüfung für Dateien
# Nutzung: checksum-verification.sh <DATEI> <ERWARTETE_SHA256>

usage() {
  echo "Usage: $0 <file> <expected_sha256>" >&2
  exit 64
}

calc_sha256() {
  local file=$1
  sha256sum "$file" | awk '{print $1}'
}

main() {
  [[ $# -eq 2 ]] || usage
  local file=$1 expected=$2
  [[ -f $file ]] || {
    echo "Datei nicht gefunden: $file" >&2
    exit 66
  }
  local got
  got=$(calc_sha256 "$file")
  if [[ "$got" == "$expected" ]]; then
    echo "OK: $file"
    exit 0
  else
    echo "MISMATCH: expected=$expected got=$got" >&2
    exit 65
  fi
}

main "$@"
