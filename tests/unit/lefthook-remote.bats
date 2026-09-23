#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  CONFIG="$REPO_ROOT/lefthook-remote.yml"
}

@test "defines pre-push hook" {
  run grep -c '^pre-push:' "$CONFIG"
  assert_success
  assert_output "1"
}

@test "does not define pre-commit hook" {
  run grep -c '^pre-commit:' "$CONFIG"
  assert_failure
  assert_output "0"
}

@test "documents why vulnix-scan is pre-push only" {
  run grep -q 'requires nix build result' "$CONFIG"
  assert_success
}
