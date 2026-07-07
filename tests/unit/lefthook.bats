#!/usr/bin/env bats

setup() {
  load "${BATS_LIB_PATH}/bats-support/load.bash"
  load "${BATS_LIB_PATH}/bats-assert/load.bash"

  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  CONFIG="$REPO_ROOT/lefthook.yml"
}

@test "defines pre-commit hook" {
  run grep -c '^pre-commit:' "$CONFIG"
  assert_success
  assert_output "1"
}

@test "defines pre-push hook" {
  run grep -c '^pre-push:' "$CONFIG"
  assert_success
  assert_output "1"
}

@test "pre-commit has markdownlint command" {
  run bash -c 'sed -n "/^pre-commit:/,/^pre-push:/p" "$1" | grep -c "markdownlint:"' -- "$CONFIG"
  assert_success
  assert_output "1"
}

@test "pre-push has markdownlint command" {
  run bash -c 'sed -n "/^pre-push:/,\$p" "$1" | grep -c "markdownlint:"' -- "$CONFIG"
  assert_success
  assert_output "1"
}

@test "pre-commit markdownlint uses glob for md files" {
  run bash -c 'sed -n "/^pre-commit:/,/^pre-push:/p" "$1" | grep -q "glob:.*\\.md"' -- "$CONFIG"
  assert_success
}

@test "pre-push markdownlint uses glob for md files" {
  run bash -c 'sed -n "/^pre-push:/,\$p" "$1" | grep -q "glob:.*\\.md"' -- "$CONFIG"
  assert_success
}

@test "pre-commit markdownlint uses timeout" {
  run bash -c 'sed -n "/^pre-commit:/,/^pre-push:/p" "$1" | grep "markdownlint" | grep -q "timeout"' -- "$CONFIG"
  assert_success
}

@test "pre-push markdownlint uses timeout" {
  run bash -c 'sed -n "/^pre-push:/,\$p" "$1" | grep "markdownlint" | grep -q "timeout"' -- "$CONFIG"
  assert_success
}

@test "pre-commit markdownlint lints staged files" {
  run bash -c 'sed -n "/^pre-commit:/,/^pre-push:/p" "$1" | grep -q "{staged_files}"' -- "$CONFIG"
  assert_success
}

@test "pre-push markdownlint lints all files" {
  run bash -c 'sed -n "/^pre-push:/,\$p" "$1" | grep -q "{all_files}"' -- "$CONFIG"
  assert_success
}
