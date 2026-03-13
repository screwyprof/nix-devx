# Hello

A Go project managed with Nix and Claude Code.

## Setup

```bash
# Init from template
nix flake init -t github:screwyprof/nix-devx#goenv

# Set your module name (updates go.mod, .golangci.yml, package.nix)
./init.sh github.com/yourname/yourproject

# Initialize git and dev environment
git init && git add -A
cp .envrc.example .envrc && direnv allow
```

## Prerequisites

- [Nix](https://nixos.org/) with flakes enabled
- [direnv](https://direnv.net/) (recommended)

## Usage

```bash
make help       # See all available commands
make run        # Run the application
make test       # Run tests with race detection
make fmt        # Format Go code
make lint       # Run golangci-lint
make check      # Format + lint + test
make coverage   # Run tests with coverage report
```

## Building

```bash
# Build with Nix (hermetic, reproducible)
nix build

# Build with Go (fast, local)
make build
```

## Formatting

`nix fmt` formats both Nix and Go files via treefmt:
- `.nix` files — nixfmt
- `.go` files — golangci-lint (gofumpt, golines, gci, goimports)

## Dev Container

Open in VS Code with the Dev Containers extension for a fully configured
environment with Go tooling, Claude Code, and MCP servers.
