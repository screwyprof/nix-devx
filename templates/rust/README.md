# Rust Template

Rust development environment with nix-devx modules.

## Usage

```bash
nix flake init -t github:screwyprof/nix-devx#rust
```

## What's Included

- Rust toolchain (rustc, cargo)
- Cargo extensions (bacon, cargo-edit, cargo-audit, cargo-nextest, cargo-watch)
- Code coverage tools (lcov, cargo-llvm-cov auto-install)
- Pre-commit hooks for Rust
- Per-project CARGO_HOME isolation

## After Init

1. Run `direnv allow` or `nix develop`
2. Start coding!
