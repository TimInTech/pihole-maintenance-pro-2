#!/usr/bin/env bats

load test_helpers.bash

setup() {
  mkdir -p ./logs
}

@test "health returns 0 when components are OK or skipped" {
  run bash -c "CONFIG_FILE=examples/config.cfg LOG_LEVEL=debug ./src/pihole_maintenance_pro.sh --health"
  [ "$status" -eq 0 ]
}
