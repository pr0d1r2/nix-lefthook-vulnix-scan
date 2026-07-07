## §D — Description

nix-lefthook-vulnix-scan is a Nix flake that provides a lefthook-compatible
vulnerability scanner for Nix build outputs. It wraps
[vulnix](https://github.com/nix-community/vulnix) to scan build result
symlinks (`result`, `result-darwin`) for known CVEs, with support for
project-specific and system-level whitelists, exponential-backoff retries,
and an NVD mirror to avoid rate limiting. The package is intended for Nix
developers who want automated CVE scanning as a git pre-push hook, usable
either as a flake input or as a remote lefthook configuration.

## §V — Invariants

1. The flake must evaluate and build on all four supported systems:
    `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
2. CI runs on both `ubuntu-latest` and `macos-latest` via the
    `nix-lefthook-ci-action`.
3. All shell scripts pass `shellcheck` and `shfmt`.
4. All Nix files pass `statix`, `deadnix`, `nixfmt`, and the
    no-embedded-shell check.
5. All YAML files pass `yamllint` (`.yamllint.yml` config).
6. All files pass `editorconfig-checker` (`.editorconfig` config).
7. All files end with a final newline, have no trailing whitespace, and
    contain no git conflict markers.
8. No tracked file exceeds the size limits in
    `config/lefthook/file_size_limits.yml` (default 4096 bytes; `.lock`
    65536; `.nix` 10240; `.md` 10240).
9. Nix files do not contain local filesystem paths (`git-no-local-paths`).
10. Shell scripts must not embed functions — separate scripts are used
    instead.
11. Shell scripts must not be called via `./script`; always prepend with
    `bash script`.
12. Every shell script has a 1-to-1 bats unit test under `tests/unit/`.
13. `bats tests/unit` must pass with zero failures.
14. Lefthook checks use `timeout` to bound execution time.
15. The `dev.sh` shell hook installs lefthook when `.git/hooks/pre-commit`
    is absent.
16. Markdown files pass `markdownlint` (line-length disabled via
    `.markdownlint.yml`).

## §I — Interfaces

### CLI (Nix package)

`lefthook-vulnix-scan` — wrapped shell script installed via
`nix build` / `nix develop`. No flags; configured entirely through
environment variables.

### Environment variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `VULNIX_RESULTS` | space-separated paths | `result-darwin result` | Build result symlinks to scan |
| `VULNIX_WHITELIST` | path | `.vulnix-whitelist.toml` | Project whitelist file |
| `VULNIX_WHITELIST_SYSTEM` | path | `.vulnix-whitelist-system.toml` | System/CI whitelist file |
| `VULNIX_MIRROR` | URL | `https://pr0d1r2.github.io/nix-vulnix-nvd-mirror/` | NVD feed mirror |
| `VULNIX_RETRIES` | integer | `3` | Max retry attempts per result |
| `VULNIX_RETRY_DELAY` | integer (seconds) | `5` | Base delay for exponential backoff |
| `LEFTHOOK_VULNIX_SCAN_TIMEOUT` | integer (seconds) | `120` | Outer timeout wrapping the scan |
| `BATS_LIB_PATH` | path | set by `dev.sh` | Bats helper library path (dev shell only) |
| `NIX_CONFIG` | string | set by `dev.sh` | Enables `nix-command flakes` (dev shell only) |

### Config files

| File | Format | Purpose |
|---|---|---|
| `flake.nix` | Nix | Flake definition: package, dev shells, lefthook wrappers |
| `lefthook.yml` | YAML | Local lefthook config with remotes and pre-push vulnix-scan |
| `lefthook-remote.yml` | YAML | Remote lefthook config (pre-push only) for consumers |
| `.vulnix-whitelist.toml` | TOML | Project-specific CVE whitelist (tracked) |
| `.vulnix-whitelist-system.toml` | TOML | System/CI whitelist (gitignored) |
| `.vulnix-whitelist-system.toml.example` | TOML | Template for system whitelist |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size caps |
| `dev.sh` | Shell (sourced) | Dev shell hook: sets `BATS_LIB_PATH`, installs lefthook |
| `.envrc` | direnv | Loads the flake dev shell |

### Flake outputs

| Output | Description |
|---|---|
| `packages.<system>.default` | `lefthook-vulnix-scan` wrapped shell application |
| `devShells.<system>.default` | Dev shell with all linters, bats, lefthook, and vulnix |
| `devShells.<system>.ci` | Alias for `default` dev shell |

### Remote lefthook integration

Consumers add a `remotes` entry in their `lefthook.yml` pointing to this
repo's `lefthook-remote.yml`, which registers the `vulnix-scan` command
under `pre-push`.

## §T — Tasks

| status | id | goal |
|---|---|---|
| `x` | T1 | Add test for `VULNIX_WHITELIST_SYSTEM` env var — currently untested |
| `x` | T2 | Add test for `VULNIX_MIRROR` env var — currently untested |
| `x` | T3 | Add test for retry logic (vulnix fails then succeeds on subsequent attempt) |
| `x` | T4 | Add test for `VULNIX_RETRIES` env var — currently untested |
| `x` | T5 | Add test for `VULNIX_RETRY_DELAY` env var — currently untested |
| `.` | T6 | Speed up the "fails when vulnix exits non-zero" test by setting `VULNIX_RETRIES=1` to avoid 15s of retry sleeps |
| `.` | T7 | Add `watch_file` entries to `.envrc` for `dev.sh` and `flake.nix` so direnv reloads on changes |
| `.` | T8 | Add `lefthook-remote.yml` to `pre-commit` in addition to `pre-push` (or document why vulnix-scan is pre-push only) |
| `.` | T9 | Add a `markdownlint` lefthook check — markdown files exist but no linter is configured for them in `lefthook.yml` |

## §B — Bugs / Known Issues

1. **Slow failure test**: The `@test "fails when vulnix exits non-zero"`
    test in `lefthook-vulnix-scan.bats` does not override `VULNIX_RETRIES`.
    With the default of 3 retries and exponential backoff (5s + 10s), the
    test waits ~15 seconds before failing. Setting `VULNIX_RETRIES=1` would
    make it instant.

2. **Missing env var test coverage**: The variables `VULNIX_WHITELIST_SYSTEM`,
    `VULNIX_MIRROR`, `VULNIX_RETRIES`, and `VULNIX_RETRY_DELAY` are
    implemented in `lefthook-vulnix-scan.sh` but have no corresponding
    bats tests.

3. **No retry-success test**: There is no test verifying that the retry
    logic actually works (i.e., vulnix fails on attempt 1 but succeeds on
    attempt 2). The only failure test always exits non-zero.

4. **`.envrc` does not watch dependencies**: The `.envrc` file contains
    only `use flake` and does not `watch_file` for `dev.sh`, `flake.nix`,
    or `flake.lock`. Changes to these files may not trigger a direnv
    reload.

5. **Whitelist maintenance burden**: The `.vulnix-whitelist.toml` file
    contains 130+ entries mixing false positives with real CVEs that are
    whitelisted due to rebuild cost. There is no automated mechanism to
    prune entries when nixpkgs bumps fix the underlying CVEs, so stale
    entries accumulate silently.

6. **`lefthook-remote.yml` is pre-push only**: The remote config only
    defines `pre-push`, not `pre-commit`. This is likely intentional
    (vulnix needs build results), but it is not documented and differs
    from the project skill rule that all checks should be in both hooks.

7. **`markdownlint` not in lefthook**: A `.markdownlint.yml` config exists
    and markdown files are tracked, but there is no `markdownlint` command
    in `lefthook.yml`. Per the linter skill, every tracked file type needs
    a lefthook linter.

8. **TOML files have no linter**: `.vulnix-whitelist.toml` and
    `.vulnix-whitelist-system.toml.example` are tracked TOML files with no
    corresponding linter in `lefthook.yml`.

9. **SPEC.md editorconfig and file-size failures** (2026-07-07, fixed):
    Numbered list continuation lines used 3-space indentation violating
    `.editorconfig` `indent_size = 2`. Also exceeded the default 4096-byte
    file-size limit for `.md`. Fixed indentation to 4 spaces and added
    `md: 10240` to `config/lefthook/file_size_limits.yml`.
