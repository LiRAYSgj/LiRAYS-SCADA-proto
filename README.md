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
- `scripts/generate.sh`: regenerate language outputs
- `scripts/verify-generated.sh`: CI check for generated-code drift
- `scripts/check-version-sync.sh`: validates one shared version across all packages

## Local Workflow

1. Update `.proto` files under `proto/`.
2. Regenerate code:
   - `./scripts/generate.sh`
3. Commit both schema and generated outputs.

## Versioning

A single lockstep version is stored in `VERSION` and must match:

- `packages/rust/lirays-scada-proto/Cargo.toml`
- `packages/python/lirays-scada-proto/pyproject.toml`
- `packages/js/lirays-scada-proto/package.json`

## CI and Release

- `CI` workflow runs lint, breaking checks, and compiles all packages.
- `Release` workflow triggers on tags `vX.Y.Z`.
- Release publishing is gated: **all Rust/Python/JS compile checks must pass before any publish job runs**.

### Required GitHub Secrets

- `CARGO_REGISTRY_TOKEN`
- `PYPI_API_TOKEN`
- `NPM_TOKEN`
