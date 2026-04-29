# shellcheck shell=bash
# Lefthook-compatible vulnix scan wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

results="${VULNIX_RESULTS:-result-darwin result}"
whitelist="${VULNIX_WHITELIST:-.vulnix-whitelist.toml}"
system_whitelist="${VULNIX_WHITELIST_SYSTEM:-.vulnix-whitelist-system.toml}"
mirror="${VULNIX_MIRROR:-https://pr0d1r2.github.io/nix-vulnix-nvd-mirror/}"

whitelist_args=()
[ -f "$whitelist" ] && whitelist_args+=(--whitelist "$whitelist")
[ -f "$system_whitelist" ] && whitelist_args+=(--whitelist "$system_whitelist")

max_retries="${VULNIX_RETRIES:-3}"
base_delay="${VULNIX_RETRY_DELAY:-15}"

found=0
for r in $results; do
    [ -e "$r" ] || continue
    attempt=1
    while [ "$attempt" -le "$max_retries" ]; do
        if vulnix --mirror "$mirror" "${whitelist_args[@]}" "./$r"; then
            break
        fi
        if [ "$attempt" -eq "$max_retries" ]; then
            echo "vulnix-scan: failed after $max_retries attempts for $r" >&2
            exit 1
        fi
        delay=$((base_delay * (2 ** (attempt - 1))))
        echo "vulnix-scan: attempt $attempt failed, retrying in ${delay}s..." >&2
        sleep "$delay"
        attempt=$((attempt + 1))
    done
    found=1
done

if [ "$found" -eq 0 ]; then
    echo "vulnix-scan: no result symlinks found, skipping"
fi
