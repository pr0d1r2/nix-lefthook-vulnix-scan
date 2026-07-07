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

## NVD Mirror

NVD feeds are served from a [GitHub Pages mirror](https://github.com/pr0d1r2/nix-vulnix-nvd-mirror) to avoid NVD rate limiting. The mirror updates daily and eliminates the need for local NVD cache warming.

Override with `VULNIX_MIRROR` if you run your own mirror.

## Whitelists

- `.vulnix-whitelist.toml` — project-specific whitelist (tracked in git)
- `.vulnix-whitelist-system.toml` — system/CI whitelist (gitignored, copy from `.vulnix-whitelist-system.toml.example`)

```bash
cp .vulnix-whitelist-system.toml.example .vulnix-whitelist-system.toml
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `VULNIX_RESULTS` | `result-darwin result` | Space-separated list of result symlinks to scan |
| `VULNIX_WHITELIST` | `.vulnix-whitelist.toml` | Path to project whitelist file |
| `VULNIX_WHITELIST_SYSTEM` | `.vulnix-whitelist-system.toml` | Path to system whitelist file |
| `VULNIX_MIRROR` | `https://pr0d1r2.github.io/nix-vulnix-nvd-mirror/` | NVD feed mirror URL |
| `VULNIX_RETRIES` | `3` | Number of retry attempts |
| `VULNIX_RETRY_DELAY` | `5` | Base delay in seconds (exponential backoff) |
| `LEFTHOOK_VULNIX_SCAN_TIMEOUT` | `120` | Outer timeout in seconds |

## Development

```bash
nix develop  # or use direnv via .envrc
bats tests/unit
```

## License

MIT
