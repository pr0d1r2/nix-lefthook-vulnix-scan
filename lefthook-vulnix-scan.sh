# shellcheck shell=bash
# Lefthook-compatible vulnix scan wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

results="${VULNIX_RESULTS:-result-darwin result}"
whitelist="${VULNIX_WHITELIST:-.vulnix-whitelist.toml}"
system_whitelist="${VULNIX_WHITELIST_SYSTEM:-.vulnix-whitelist-system.toml}"

whitelist_args=()
[ -f "$whitelist" ] && whitelist_args+=(--whitelist "$whitelist")
[ -f "$system_whitelist" ] && whitelist_args+=(--whitelist "$system_whitelist")

found=0
for r in $results; do
  [ -e "$r" ] && found=1
done

if [ "$found" -eq 0 ]; then
  echo "vulnix-scan: no result symlinks found, skipping"
  exit 0
fi

scan_args=()
if [ -n "${VULNIX_MIRROR:-}" ]; then
  scan_args+=(--mirror "$VULNIX_MIRROR")
else
  cache_dir="$(mktemp -d)"
  trap 'rm -rf "$cache_dir"' EXIT
  cp "$VULNIX_CACHE_SOURCE/Data.fs" "$cache_dir/Data.fs"
  scan_args+=(-c "$cache_dir")
  export VULNIX_OFFLINE=1
fi

for r in $results; do
  [ -e "$r" ] || continue
  if [ -n "${VULNIX_MIRROR:-}" ]; then
    max_retries="${VULNIX_RETRIES:-3}"
    base_delay="${VULNIX_RETRY_DELAY:-5}"
    attempt=1
    while [ "$attempt" -le "$max_retries" ]; do
      if vulnix "${scan_args[@]}" "${whitelist_args[@]}" "./$r"; then
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
  elif ! vulnix "${scan_args[@]}" "${whitelist_args[@]}" "./$r"; then
    echo "vulnix-scan: scan failed for $r" >&2
    exit 1
  fi
done
