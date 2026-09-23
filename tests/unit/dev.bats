#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert

    TESTDIR="$(mktemp -d)"
    git init "$TESTDIR/repo" >/dev/null 2>&1
    mkdir -p "$TESTDIR/repo/.git/hooks"
    touch "$TESTDIR/repo/.git/hooks/pre-commit"

    sed 's|@BATS_LIB_PATH@|/test/lib|' dev.sh > "$TESTDIR/dev.sh"

    mkdir -p "$TESTDIR/bin"
    cat > "$TESTDIR/bin/lefthook" <<'SH'
#!/usr/bin/env bash
echo "lefthook $*" >> "$LEFTHOOK_LOG"
SH
    chmod +x "$TESTDIR/bin/lefthook"
}

teardown() {
    rm -rf "${TESTDIR:?}"
}

@test "sets BATS_LIB_PATH from placeholder" {
    cd "$TESTDIR/repo"
    run bash -c 'unset BATS_LIB_PATH; source "$1"; echo "$BATS_LIB_PATH"' -- "$TESTDIR/dev.sh"
    assert_success
    assert_output "/test/lib/share/bats"
}

@test "runs lefthook install when hooks are missing" {
    cd "$TESTDIR/repo"
    rm "$TESTDIR/repo/.git/hooks/pre-commit"
    # shellcheck disable=SC2030
    export PATH="$TESTDIR/bin:$PATH"
    # shellcheck disable=SC2030
    export LEFTHOOK_LOG="$TESTDIR/log"
    # shellcheck disable=SC1091
    source "$TESTDIR/dev.sh"
    assert [ -f "$LEFTHOOK_LOG" ]
    run cat "$LEFTHOOK_LOG"
    assert_output "lefthook install"
}

@test "skips lefthook install when hooks exist" {
    cd "$TESTDIR/repo"
    # shellcheck disable=SC2031
    export PATH="$TESTDIR/bin:$PATH"
    # shellcheck disable=SC2031
    export LEFTHOOK_LOG="$TESTDIR/log"
    # shellcheck disable=SC1091
    source "$TESTDIR/dev.sh"
    assert [ ! -f "$LEFTHOOK_LOG" ]
}
