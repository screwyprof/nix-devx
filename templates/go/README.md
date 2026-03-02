# Go Template

Go development environment with nix-devx modules.

## Usage

```bash
nix flake init -t github:screwyprof/nix-devx#go
```

## What's Included

- Go toolchain (go, gopls, delve, gotools)
- Linting (golangci-lint, gofumpt, golines, gci)
- Pre-commit hooks for Go
- Per-project GOBIN isolation

## After Init

1. Run `direnv allow` or `nix develop`
2. Start coding!
