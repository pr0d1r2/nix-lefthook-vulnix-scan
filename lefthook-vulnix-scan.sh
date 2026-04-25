# shellcheck shell=bash
# Lefthook-compatible vulnix scan wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

results="${VULNIX_RESULTS:-result-darwin result}"
whitelist="${VULNIX_WHITELIST:-.vulnix-whitelist.toml}"

found=0
for r in $results; do
    [ -e "$r" ] || continue
    whitelist_args=()
    if [ -f "$whitelist" ]; then
        whitelist_args=(--whitelist "$whitelist")
    fi
    vulnix "${whitelist_args[@]}" "./$r" || exit 1
    found=1
done

if [ "$found" -eq 0 ]; then
    echo "vulnix-scan: no result symlinks found, skipping"
fi
