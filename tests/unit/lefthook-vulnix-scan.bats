#!/usr/bin/env bats

setup() {
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"
    load "$BATS_LIB_PATH/bats-file/load"

    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    SCRIPT="$REPO_ROOT/lefthook-vulnix-scan.sh"

    TEST_TEMP="$(mktemp -d)"

    mkdir -p "$TEST_TEMP/bin"
    cat > "$TEST_TEMP/bin/vulnix" <<'SH'
#!/usr/bin/env bash
echo "vulnix $*" >> "$VULNIX_LOG"
SH
    chmod +x "$TEST_TEMP/bin/vulnix"
    export VULNIX_LOG="$TEST_TEMP/vulnix.log"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

run_script() {
    cd "$TEST_TEMP" && PATH="$TEST_TEMP/bin:$PATH" bash "$SCRIPT"
}

@test "skips when no result symlinks exist" {
    run run_script
    assert_success
    assert_output --partial "no result symlinks found, skipping"
}

@test "scans result-darwin symlink" {
    mkdir "$TEST_TEMP/result-darwin"
    run run_script
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "./result-darwin"
}

@test "scans result symlink" {
    mkdir "$TEST_TEMP/result"
    run run_script
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "./result"
}

@test "scans both result symlinks" {
    mkdir "$TEST_TEMP/result-darwin"
    mkdir "$TEST_TEMP/result"
    run run_script
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "./result-darwin"
    assert_output --partial "./result"
}

@test "passes whitelist when file exists" {
    mkdir "$TEST_TEMP/result"
    touch "$TEST_TEMP/.vulnix-whitelist.toml"
    run run_script
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "--whitelist"
    assert_output --partial ".vulnix-whitelist.toml"
}

@test "skips whitelist when file missing" {
    mkdir "$TEST_TEMP/result"
    run run_script
    assert_success
    run cat "$VULNIX_LOG"
    refute_output --partial "--whitelist"
}

@test "respects VULNIX_RESULTS env var" {
    mkdir "$TEST_TEMP/custom-result"
    run bash -c "cd '$TEST_TEMP' && PATH='$TEST_TEMP/bin:$PATH' VULNIX_RESULTS='custom-result' bash '$SCRIPT'"
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "./custom-result"
}

@test "respects VULNIX_WHITELIST env var" {
    mkdir "$TEST_TEMP/result"
    touch "$TEST_TEMP/my-whitelist.toml"
    run bash -c "cd '$TEST_TEMP' && PATH='$TEST_TEMP/bin:$PATH' VULNIX_WHITELIST='my-whitelist.toml' bash '$SCRIPT'"
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "my-whitelist.toml"
}

@test "respects VULNIX_WHITELIST_SYSTEM env var" {
    mkdir "$TEST_TEMP/result"
    touch "$TEST_TEMP/my-system-whitelist.toml"
    run bash -c "cd '$TEST_TEMP' && PATH='$TEST_TEMP/bin:$PATH' VULNIX_WHITELIST_SYSTEM='my-system-whitelist.toml' bash '$SCRIPT'"
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "my-system-whitelist.toml"
}

@test "respects VULNIX_MIRROR env var" {
    mkdir "$TEST_TEMP/result"
    run bash -c "cd '$TEST_TEMP' && PATH='$TEST_TEMP/bin:$PATH' VULNIX_MIRROR='https://custom-mirror.example.com/' bash '$SCRIPT'"
    assert_success
    run cat "$VULNIX_LOG"
    assert_output --partial "--mirror https://custom-mirror.example.com/"
}

@test "respects VULNIX_RETRIES env var" {
    mkdir "$TEST_TEMP/result"
    cat > "$TEST_TEMP/bin/vulnix" <<'SH'
#!/usr/bin/env bash
exit 1
SH
    chmod +x "$TEST_TEMP/bin/vulnix"
    run bash -c "cd '$TEST_TEMP' && PATH='$TEST_TEMP/bin:$PATH' VULNIX_RETRIES=2 VULNIX_RETRY_DELAY=0 bash '$SCRIPT'"
    assert_failure
    assert_output --partial "failed after 2 attempts"
}

@test "retries and succeeds when vulnix fails then succeeds" {
    mkdir "$TEST_TEMP/result"
    cat > "$TEST_TEMP/bin/vulnix" <<SH
#!/usr/bin/env bash
echo "vulnix \$*" >> "$VULNIX_LOG"
COUNTER_FILE="$TEST_TEMP/vulnix_counter"
count=0
[ -f "\$COUNTER_FILE" ] && count=\$(cat "\$COUNTER_FILE")
count=\$((count + 1))
echo "\$count" > "\$COUNTER_FILE"
if [ "\$count" -le 1 ]; then
  exit 1
fi
exit 0
SH
    chmod +x "$TEST_TEMP/bin/vulnix"
    run bash -c "cd '$TEST_TEMP' && PATH='$TEST_TEMP/bin:$PATH' VULNIX_RETRIES=2 VULNIX_RETRY_DELAY=0 bash '$SCRIPT'"
    assert_success
    assert_output --partial "attempt 1 failed, retrying in 0s"
}

@test "fails when vulnix exits non-zero" {
    mkdir "$TEST_TEMP/result"
    cat > "$TEST_TEMP/bin/vulnix" <<'SH'
#!/usr/bin/env bash
exit 1
SH
    chmod +x "$TEST_TEMP/bin/vulnix"
    run run_script
    assert_failure
}
