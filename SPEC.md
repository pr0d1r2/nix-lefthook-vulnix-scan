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
16. Markdown files pass `markdownlint` (line-length and first-line-heading
    disabled via `.markdownlint.yml`).
17. vulnix's NVD-download read timeout is patched to 60s (from the upstream
    hardcoded 10s), with a build-time `grep` guard asserting the patch
    landed — so a slow-but-alive mirror does not RED-fail the scan.

## §I — Interfaces

### CLI (Nix package)

`lefthook-vulnix-scan` — wrapped shell script installed via
`nix build` / `nix develop`. No flags; configured entirely through
environment variables.

### Environment variables

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `VULNIX_RESULTS` | space-separated paths | `result-darwin result` | Build result symlinks to scan |
| `VULNIX_WHITELIST` | path | `.vulnix-whitelist.toml` | Project whitelist file |
| `VULNIX_WHITELIST_SYSTEM` | path | `.vulnix-whitelist-system.toml` | System/CI whitelist file |
| `VULNIX_MIRROR` | URL | unset | NVD feed mirror; enables live-download fallback |
| `VULNIX_RETRIES` | integer | `3` | Live-download retry attempts per result |
| `VULNIX_RETRY_DELAY` | integer (seconds) | `5` | Live-download base retry delay |
| `LEFTHOOK_VULNIX_SCAN_TIMEOUT` | integer (seconds) | `120` | Outer timeout wrapping the scan |
| `BATS_LIB_PATH` | path | set by `dev.sh` | Bats helper library path (dev shell only) |
| `NIX_CONFIG` | string | set by `dev.sh` | Enables `nix-command flakes` (dev shell only) |

### Config files

| File | Format | Purpose |
| --- | --- | --- |
| `flake.nix` | Nix | Flake definition: package, dev shells, lefthook wrappers |
| `lefthook.yml` | YAML | Local lefthook config with remotes and pre-push vulnix-scan |
| `lefthook-remote.yml` | YAML | Remote lefthook config (pre-push only — requires nix build result symlinks) for consumers |
| `.vulnix-whitelist.toml` | TOML | Project-specific CVE whitelist (tracked) |
| `.vulnix-whitelist-system.toml` | TOML | System/CI whitelist (gitignored) |
| `.vulnix-whitelist-system.toml.example` | TOML | Template for system whitelist |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size caps |
| `dev.sh` | Shell (sourced) | Dev shell hook: sets `BATS_LIB_PATH`, installs lefthook |
| `.envrc` | direnv | Loads the flake dev shell |

### Flake outputs

| Output | Description |
| --- | --- |
| `packages.<system>.default` | `lefthook-vulnix-scan` wrapped shell application |
| `devShells.<system>.default` | Dev shell with all linters, bats, lefthook, and vulnix |
| `devShells.<system>.ci` | Alias for `default` dev shell |

### Remote lefthook integration

Consumers add a `remotes` entry in their `lefthook.yml` pointing to this
repo's `lefthook-remote.yml`, which registers the `vulnix-scan` command
under `pre-push`.

## §T — Tasks

| status | id | goal |
| --- | --- | --- |
| `x` | T1 | Add test for `VULNIX_WHITELIST_SYSTEM` env var — currently untested |
| `x` | T2 | Add test for `VULNIX_MIRROR` env var — currently untested |
| `x` | T3 | Add test for retry logic (vulnix fails then succeeds on subsequent attempt) |
| `x` | T4 | Add test for `VULNIX_RETRIES` env var — currently untested |
| `x` | T5 | Add test for `VULNIX_RETRY_DELAY` env var — currently untested |
| `x` | T6 | Speed up the "fails when vulnix exits non-zero" test by setting `VULNIX_RETRIES=1` to avoid 15s of retry sleeps |
| `x` | T7 | Add `watch_file` entries to `.envrc` for `dev.sh` and `flake.nix` so direnv reloads on changes |
| `x` | T8 | Add `lefthook-remote.yml` to `pre-commit` in addition to `pre-push` (or document why vulnix-scan is pre-push only) |
| `x` | T9 | Add a `markdownlint` lefthook check — markdown files exist but no linter is configured for them in `lefthook.yml` |

## §B — Bugs / Known Issues

1. ~~**Slow failure test**~~: Fixed. The test now sets `VULNIX_RETRIES=1`
    to avoid retry delays.

2. ~~**Missing env var test coverage**~~: Fixed. Tests for
    `VULNIX_WHITELIST_SYSTEM`, `VULNIX_MIRROR`, `VULNIX_RETRIES`, and
    `VULNIX_RETRY_DELAY` added.

3. ~~**No retry-success test**~~: Fixed. Test "retries and succeeds when
    vulnix fails then succeeds" covers the retry-then-pass path.

4. ~~**`.envrc` does not watch dependencies**~~: Fixed. `.envrc` now has
    `watch_file` entries for `dev.sh` and `flake.nix`.

5. **Whitelist maintenance burden**: The `.vulnix-whitelist.toml` file
    contains 130+ entries mixing false positives with real CVEs that are
    whitelisted due to rebuild cost. There is no automated mechanism to
    prune entries when nixpkgs bumps fix the underlying CVEs, so stale
    entries accumulate silently.

6. ~~**`lefthook-remote.yml` is pre-push only**~~: Documented. The scan
    requires nix build result symlinks (`result`, `result-darwin`) which
    are not available at commit time, so `pre-commit` is not applicable.

7. **`markdownlint` not in lefthook**: A `.markdownlint.yml` config exists
    and markdown files are tracked, but there is no `markdownlint` command
    in `lefthook.yml`. Per the linter skill, every tracked file type needs
    a lefthook linter.

8. **TOML files have no linter**: `.vulnix-whitelist.toml` and
    `.vulnix-whitelist-system.toml.example` are tracked TOML files with no
    corresponding linter in `lefthook.yml`.

9. ~~**SPEC.md editorconfig and file-size failures**~~: Fixed.
    Indentation corrected to 4 spaces and `md: 10240` added to
    `config/lefthook/file_size_limits.yml`.

10. ~~**Missing markdownlint wrappers break CI**~~: Fixed. `lefthook.yml`
    referenced `lefthook-markdownlint` and `lefthook-markdownlint-agentic`,
    but `flake.nix` never provided those wrappers, so CI failed with
    `timeout: failed to run command 'lefthook-markdownlint': No such file
    or directory` (exit 127). Added the `nix-lefthook-markdownlint` and
    `nix-lefthook-markdownlint-agentic` flake inputs and their
    `writeShellApplication` wrappers (the former also wiring the
    `is-markdown-agentic` helper).

11. ~~**vulnix NVD-download 10s timeout RED-fails on a slow-but-alive
    mirror**~~: Fixed. vulnix hardcodes `requests.get(..., timeout=10)` in
    `src/vulnix/nvd.py` (not env- or flag-configurable). The live-download
    fallback retains a guarded patch to `timeout=60`. Normal scans use the
    pre-built NVD database offline, so a dead mirror cannot RED-gate a PR.

12. ~~**Migration generated an invalid `flake.nix`**~~: Fixed. The
    vendored-to-referenced migration left orphaned helper bindings and an
    incomplete package/dev-shell expression, so guardrails failed while
    parsing the flake. Rebuilt the consumer flake around `mkConsumerFlake`'s
    `extraPackages` interface while preserving the vulnix timeout override.

13. ~~**Referenced confirm app cannot find fragment wrappers**~~: Fixed.
    The locked `mkConsumerFlake` confirm app checked generated commands
    against a PATH containing only core utilities, so markdown and YAML
    wrappers were falsely reported missing even though the development shell
    provided them. Wrapped the upstream confirm app with the materialized
    fragment packages on PATH.

14. ~~**Flake manifest check rejected output structure**~~: Fixed. The flake
    exposed helper bindings and `let` expressions in `outputs`, which the
    manifest guardrail disallows. Inlined the consumer and fragment
    definitions while preserving the custom confirm app wrapper.

15. ~~**Lock graph contained four nixpkgs nodes**~~: Fixed. Direct and
    transitive inputs independently locked nixpkgs, causing the lock-graph
    guardrail to reject the flake. Shared nixpkgs inputs now follow the
    repository's canonical node, including the unstable alias.

16. ~~**Guardrails rejected the flake formatting and repeated input keys**~~:
    Fixed. `flake.nix` was not formatted and Statix rejected the dotted
    `set-and-setting` input assignments; applied nixfmt and grouped the input
    attributes.

17. **Actionlint fragment missing from materialized hooks**: The generated
    `lefthook.yml` omitted the actionlint command despite the actions fragment
    being selected, causing the guardrail fidelity check to fail. Added the
    actionlint command to both hook phases.
