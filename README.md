# nix-lefthook-vulnix-scan

[![CI](https://github.com/pr0d1r2/nix-lefthook-vulnix-scan/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-vulnix-scan/actions/workflows/ci.yml)

Lefthook-compatible vulnix vulnerability scanner for nix build results, packaged as a Nix flake.

Scans nix build result symlinks (`result-darwin`, `result`) for known CVEs using [vulnix](https://github.com/nix-community/vulnix). Supports project-specific whitelists.

## Usage

### As a remote lefthook configuration

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

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `VULNIX_RESULTS` | `result-darwin result` | Space-separated list of result symlinks to scan |
| `VULNIX_WHITELIST` | `.vulnix-whitelist.toml` | Path to vulnix whitelist file |
| `LEFTHOOK_VULNIX_SCAN_TIMEOUT` | `120` | Timeout in seconds |

## Development

```bash
nix develop  # or use direnv via .envrc
bats tests/unit
```

## License

MIT
