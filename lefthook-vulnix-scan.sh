# shellcheck shell=bash
# Lefthook-compatible vulnix scan wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

# A consumer dev shell that also carries stock vulnix exports its
# site-packages in PYTHONPATH, which Python searches before the wrapper's
# own site dirs: the unpatched nvd.py wins, VULNIX_OFFLINE is ignored and
# the scan live-downloads NVD feeds with a 10s timeout.
unset PYTHONPATH

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

# A pre-built cache is optional. Baking one in as a build-time dependency
# makes this package unbuildable whenever the mirror's pinned feed hashes
# drift, even for consumers that scan through the mirror and never read it.
default_mirror="https://pr0d1r2.github.io/nix-vulnix-nvd-mirror/"

scan_args=()
if [ -n "${VULNIX_MIRROR:-}" ]; then
  scan_args+=(--mirror "$VULNIX_MIRROR")
elif [ -n "${VULNIX_CACHE_SOURCE:-}" ]; then
  cache_dir="$(mktemp -d)"
  trap 'rm -rf "$cache_dir"' EXIT
  cp "$VULNIX_CACHE_SOURCE/Data.fs" "$cache_dir/Data.fs"
  scan_args+=(-c "$cache_dir")
  export VULNIX_OFFLINE=1
else
  VULNIX_MIRROR="$default_mirror"
  scan_args+=(--mirror "$VULNIX_MIRROR")
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
