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

max_retries="${VULNIX_RETRIES:-3}"
retry_delay="${VULNIX_RETRY_DELAY:-5}"

found=0
for r in $results; do
    [ -e "$r" ] || continue
    attempt=1
    while [ "$attempt" -le "$max_retries" ]; do
        if vulnix "${whitelist_args[@]}" "./$r"; then
            break
        fi
        if [ "$attempt" -eq "$max_retries" ]; then
            echo "vulnix-scan: failed after $max_retries attempts for $r" >&2
            exit 1
        fi
        echo "vulnix-scan: attempt $attempt failed, retrying in ${retry_delay}s..." >&2
        sleep "$retry_delay"
        attempt=$((attempt + 1))
    done
    found=1
done

if [ "$found" -eq 0 ]; then
    echo "vulnix-scan: no result symlinks found, skipping"
fi
