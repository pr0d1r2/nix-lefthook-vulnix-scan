# Linter

Every file type tracked in git must have an assigned linter in lefthook.yml (both pre-commit and pre-push). When adding a new file type to the repo, add its linter before committing.

When adding a new linter:

1. Add the tool to both devShells in `flake.nix`
2. Add a command to both `pre-commit` and `pre-push` in `lefthook.yml`
3. Use `glob` to scope to the right file extensions
4. Pre-commit: lint `{staged_files}` only; pre-push: lint all tracked files
5. Fix any existing violations before committing

## Extension coverage

Every tracked file type, with the linter that covers it or the reason it is
exempt. `check-linter-coverage` reads this table.

| Extension | Linter | Notes |
| --------- | ------ | ----- |
| `.nix` | statix, deadnix, nixfmt, nix-no-embedded-shell, nix-flake-check | Lint, dead code, format, no embedded shell, and the flake's own checks |
| `.sh` | shellcheck, shfmt, no-shell-functions | Correctness, format, and the no-functions convention |
| `.bats` | bats-parse, bats-unit | Parse-only validation plus the suite itself; shfmt cannot parse `@test` blocks |
| `.md` | markdownlint, markdownlint-agentic | Prose lint, with the agentic ruleset for generated documents |
| `.yml` | yamllint, actionlint | YAML lint everywhere; actionlint additionally for `.github/workflows/*` |
| `.toml` | — | The vulnix whitelist, read by vulnix itself; it rejects a malformed file |
| `.example` | — | `.vulnix-whitelist-system.toml.example`, a sample never loaded by any tool |
| `.lock` | nix-flake-check | `flake.lock` is generated and validated by evaluating the flake |
| `.gitignore` | — | git's own format; no linter in the fleet reads it |
| `.editorconfig` | — | Consumed by editorconfig-checker, which lints other files rather than this one |
| `.envrc` | — | direnv stanza (`use flake`); shellcheck cannot resolve direnv's builtins |
| `.LICENSE` | — | Verbatim MIT text; linting it would edit the licence |

All files are additionally covered by `unicode-lint` (glob `*`), and commits by
`gitleaks`, `git-conflict-markers`, `git-no-local-paths` and `changelog-touched`.
