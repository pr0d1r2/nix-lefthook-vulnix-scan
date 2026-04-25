# shellcheck shell=bash
export BATS_LIB_PATH="@BATS_LIB_PATH@/share/bats"
export NIX_CONFIG="experimental-features = nix-command flakes"
[ -f .git/hooks/pre-commit ] || lefthook install
