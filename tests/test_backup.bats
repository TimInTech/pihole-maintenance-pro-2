#!/usr/bin/env bats

load test_helpers.bash

setup() {
  setup_path_with_mock
  write_mock_pihole
  mkdir -p ./backups /etc/pihole
  touch /etc/pihole/teleporter_foo.tar.gz
}

@test "backup creates file or copies teleporter" {
  run bash -c "CONFIG_FILE=examples/config.cfg LOG_LEVEL=debug BACKUP_DIR=./backups LOG_DIR=./logs ./src/pihole_maintenance_pro.sh --backup"
  [ "$status" -eq 0 ]
}
