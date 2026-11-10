# Changelog

All notable changes to this project are documented here.

## Unreleased

- Refresh the `nixpkgs-lock` pin and whitelist ruby 3.4.11 for
  CVE-2026-97229 until 2026-12-10, pending the nixpkgs 3.4.12 backport
  (pr0d1r2/nixpkgs-lock#94).
- Pin the CI guardrails workflow to a full commit SHA (`ci-lint-sha`).
- Use the project's vulnix NVD mirror by default, with an `offline` package
  output for air-gapped scans.
