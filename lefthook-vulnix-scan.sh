# shellcheck shell=bash
# Lefthook-compatible vulnix scan wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

results="${VULNIX_RESULTS:-result-darwin result}"
whitelist="${VULNIX_WHITELIST:-.vulnix-whitelist.toml}"
system_whitelist="${VULNIX_WHITELIST_SYSTEM:-.vulnix-whitelist-system.toml}"

whitelist_args=()
if [ -f "$whitelist" ] && [ -f "$system_whitelist" ]; then
    merged=$(mktemp)
    trap 'rm -f "$merged"' EXIT
    cat "$whitelist" "$system_whitelist" >"$merged"
    whitelist_args=(--whitelist "$merged")
elif [ -f "$whitelist" ]; then
    whitelist_args=(--whitelist "$whitelist")
elif [ -f "$system_whitelist" ]; then
    whitelist_args=(--whitelist "$system_whitelist")
fi

found=0
for r in $results; do
    [ -e "$r" ] || continue
    vulnix "${whitelist_args[@]}" "./$r" || exit 1
    found=1
done

if [ "$found" -eq 0 ]; then
    echo "vulnix-scan: no result symlinks found, skipping"
fi
