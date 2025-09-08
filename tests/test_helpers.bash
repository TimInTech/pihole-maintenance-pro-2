# Test-Helfer zum Mocken von pihole-Aufrufen
load() {
  :
}

setup_path_with_mock() {
  MOCK_DIR="$BATS_TEST_TMPDIR/mock"
  mkdir -p "$MOCK_DIR"
  export PATH="$MOCK_DIR:$PATH"
}

write_mock_pihole() {
  cat >"$MOCK_DIR/pihole" <<'EOS'
#!/usr/bin/env bash
set -e
case "$1" in
  -v) echo "Pi-hole version mock" ;;
  -g) echo "Gravity update mock" ;;
  -a) shift; if [[ "$1" == "-t" ]]; then echo "Teleporter backup mock"; fi ;;
  *) echo "pihole mock: $*" ;;
 esac
EOS
  chmod +x "$MOCK_DIR/pihole"
}
