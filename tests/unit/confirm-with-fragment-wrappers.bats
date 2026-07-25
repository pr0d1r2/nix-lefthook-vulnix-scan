#!/usr/bin/env bats

@test "executes the configured confirm program with all arguments" {
    mock_confirm="$BATS_TEST_TMPDIR/mock-confirm"
    cat >"$mock_confirm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
    chmod +x "$mock_confirm"

    run env CONFIRM_PROGRAM="$mock_confirm" \
        bash confirm-with-fragment-wrappers.sh first "second argument"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "first" ]
    [ "${lines[1]}" = "second argument" ]
}
