# LiRAYS-SCADA-proto

Centralized protocol buffer definitions for LiRAYS SCADA.

This repository is the source of truth (`proto/`) and publishes language-specific packages to:

- Rust (`crates.io`)
- Python (`pypi.org`)
- JavaScript (`npmjs.com`)

## Repository Layout

- `proto/`: protobuf definitions (source of truth)
- `packages/rust/lirays-scada-proto`: Rust package
- `packages/python/lirays-scada-proto`: Python package
- `packages/js/lirays-scada-proto`: JavaScript package
- `scripts/generate.sh`: generate Python/JS outputs and vendor Rust proto snapshot
- `scripts/vendor-rust-proto.sh`: copies `proto/` into the Rust crate for packaging
- `scripts/clean-generated.sh`: removes ignored generated/build artifacts
- `scripts/check-version-sync.sh`: validates one shared version across all packages

## Local Workflow

Prerequisites:

- `protoc` installed locally (for Python/JS generation)
- JS plugin installed locally:
  - `npm install --prefix packages/js/lirays-scada-proto`

1. Update `.proto` files under `proto/`.
2. Regenerate Python and JavaScript code:
   - `./scripts/generate.sh python js`
3. Rust bindings are generated at compile time via `build.rs`.
4. Commit schema and package metadata changes. Generated wrappers are not committed.
5. Optional cleanup of ignored generated files:
   - Preview: `./scripts/clean-generated.sh --dry-run`
   - Remove: `./scripts/clean-generated.sh`

## Versioning

A single lockstep version is stored in `VERSION` and must match:

- `packages/rust/lirays-scada-proto/Cargo.toml`
- `packages/python/lirays-scada-proto/pyproject.toml`
- `packages/js/lirays-scada-proto/package.json`

## CI and Release

- `CI` workflow runs lint, breaking checks, and compiles all packages.
- `Release` workflow triggers on tags `vX.Y.Z`.
- Release publishing is gated: **all Rust/Python/JS compile checks must pass before any publish job runs**.
- Rust release job vendors `proto/` into the crate at runtime and publishes with `--allow-dirty`.

### Required GitHub Secrets

- `CARGO_REGISTRY_TOKEN`
- `PYPI_API_TOKEN`
- `NPM_TOKEN`
