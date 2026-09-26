# shellcheck shell=bash
export BATS_LIB_PATH="@BATS_LIB_PATH@/share/bats"
export NIX_CONFIG="experimental-features = nix-command flakes"
# Specs live in tests/unit, not the hook's default tests/.
export LEFTHOOK_TDD_SPEC_DIR="tests/unit"
[ -f .git/hooks/pre-commit ] || lefthook install
