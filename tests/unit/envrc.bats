#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  TESTDIR="$(mktemp -d)"
  export WATCH_LOG="$TESTDIR/watched"
}

teardown() {
  rm -rf "${TESTDIR:?}"
}

@test "watches dev.sh for changes" {
  run bash -c '
    watch_file() { echo "$1" >> "$WATCH_LOG"; }
    use() { :; }
    source .envrc
    grep -q "dev.sh" "$WATCH_LOG"
  '
  assert_success
}

@test "watches flake.nix for changes" {
  run bash -c '
    watch_file() { echo "$1" >> "$WATCH_LOG"; }
    use() { :; }
    source .envrc
    grep -q "flake.nix" "$WATCH_LOG"
  '
  assert_success
}

@test "loads flake dev shell" {
  run bash -c '
    USE_LOG=""
    watch_file() { :; }
    use() { USE_LOG="$*"; echo "$USE_LOG"; }
    source .envrc
  '
  assert_success
  assert_output "flake"
}
