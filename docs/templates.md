# Templates

nix-devx provides project templates for quick setup.

```bash
# List all available templates
nix flake show github:screwyprof/nix-devx

# Initialize a new project from a template
nix flake init -t github:screwyprof/nix-devx#<template-name>
```

## Available Templates

### minimal

A bare-bones flake-parts setup with nixpkgs and a basic devShell.

```bash
nix flake init -t github:screwyprof/nix-devx#minimal
```

**Includes:**
- flake-parts framework
- nixpkgs (unstable)
- Basic devShell

---

### go

Go development environment with linting and pre-commit hooks.

```bash
nix flake init -t github:screwyprof/nix-devx#go
```

**Includes:**
- Go toolchain (go, gopls, delve, gotools)
- Linting (golangci-lint, gofumpt, golines, gci)
- Pre-commit hooks for Go
- Per-project GOBIN isolation

---

### rust

Rust development environment with cargo extensions.

```bash
nix flake init -t github:screwyprof/nix-devx#rust
```

**Includes:**
- Rust toolchain (rustc, cargo)
- Cargo extensions (bacon, cargo-edit, cargo-audit, cargo-nextest, cargo-watch)
- Code coverage tools
- Pre-commit hooks for Rust
- Per-project CARGO_HOME isolation

---

### nix

Nix development environment with formatting and linting.

```bash
nix flake init -t github:screwyprof/nix-devx#nix
```

**Includes:**
- Nix tooling (nixfmt, statix, deadnix)
- Pre-commit hooks for Nix
- Formatter configuration

---

### claude

Claude Code environment with MCP servers.

```bash
nix flake init -t github:screwyprof/nix-devx#claude
```

**Includes:**
- Claude Code with configurable wrapper
- MCP servers (memory, sequential-thinking)
- Per-project config directory isolation
- MCP servers included in devShell

## After Initialization

1. Set required environment variables (e.g., `ANTHROPIC_AUTH_TOKEN` for Claude)
2. Run `direnv allow` or `nix develop`
3. Start coding!

## Customizing Templates

Templates are starting points. After initialization, you can:

1. Add more modules by importing them in `flake.nix`:

```nix
imports = [
  nix-devx.flakeModules.languages-go
  nix-devx.flakeModules.ai-claude  # Add Claude support
];
```

2. Stack multiple devShells:

```nix
devShells.default = pkgs.mkShellNoCC {
  inputsFrom = [
    config.languages.go.devShell
    config.ai.claude.devShell
  ];
};
```

3. Add project-specific packages:

```nix
devShells.default = pkgs.mkShellNoCC {
  inputsFrom = [ config.languages.go.devShell ];

  nativeBuildInputs = with pkgs; [
    # Add your packages here
    protobuf
  ];
};
```

## Testing Templates Locally

If you're developing nix-devx itself, test templates locally:

```bash
cd /tmp
mkdir test-project && cd test-project
nix flake init -t /path/to/nix-devx#go
```
