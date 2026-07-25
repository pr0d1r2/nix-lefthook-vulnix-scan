# nix-lefthook-vulnix-scan

[![CI](https://github.com/pr0d1r2/nix-lefthook-vulnix-scan/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-vulnix-scan/actions/workflows/ci.yml)

Lefthook-compatible vulnix vulnerability scanner for nix build results, packaged as a Nix flake.

Scans nix build result symlinks (`result-darwin`, `result`) for known CVEs using [vulnix](https://github.com/nix-community/vulnix). Supports project-specific whitelists.

## Usage

### As a remote lefthook configuration

The remote config registers vulnix-scan under `pre-push` only. It is not
available as a `pre-commit` hook because the scan requires nix build result
symlinks (`result`, `result-darwin`) which are not available at commit time.

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-vulnix-scan
    ref: main
    configs:
      - lefthook-remote.yml
```

### As a flake input

```nix
{
  inputs.nix-lefthook-vulnix-scan.url = "github:pr0d1r2/nix-lefthook-vulnix-scan";

  # In devShell packages:
  nix-lefthook-vulnix-scan.packages.${system}.default
}
```

## NVD cache

Scans use the pre-built `Data.fs` from
[nix-vulnix-nvd-mirror](https://github.com/pr0d1r2/nix-vulnix-nvd-mirror).
The package copies it from the Nix store to a writable temporary directory and
runs vulnix offline, so scans do not download NVD feeds.

Set `VULNIX_MIRROR` to opt into live downloads from a custom mirror as a
fallback. Retry settings apply only to this network fallback.

## Whitelists

- `.vulnix-whitelist.toml` — project-specific whitelist (tracked in git)
- `.vulnix-whitelist-system.toml` — system/CI whitelist (gitignored, copy from `.vulnix-whitelist-system.toml.example`)

```bash
cp .vulnix-whitelist-system.toml.example .vulnix-whitelist-system.toml
```

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `VULNIX_RESULTS` | `result-darwin result` | Space-separated list of result symlinks to scan |
| `VULNIX_WHITELIST` | `.vulnix-whitelist.toml` | Path to project whitelist file |
| `VULNIX_WHITELIST_SYSTEM` | `.vulnix-whitelist-system.toml` | Path to system whitelist file |
| `VULNIX_MIRROR` | unset | NVD feed mirror URL; enables the network fallback |
| `VULNIX_RETRIES` | `3` | Network fallback retry attempts |
| `VULNIX_RETRY_DELAY` | `5` | Network fallback base delay (exponential backoff) |
| `LEFTHOOK_VULNIX_SCAN_TIMEOUT` | `120` | Outer timeout in seconds |

## Development

```bash
nix develop  # or use direnv via .envrc
bats tests/unit
```

## License

MIT
