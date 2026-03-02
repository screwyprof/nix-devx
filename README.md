# nix-devx

Modular development environments with flake-parts.

## What's Included

- **Language modules**: Go, Rust, Nix
- **AI modules**: Claude Code, BMad Method
- **Project templates**: Quick-start templates for new projects
- **Dev container patterns**: Host vs dev container configuration

## Quick Start

### As a Flake Input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nix-devx.url = "github:screwyprof/nix-devx";
    nix-devx.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, nix-devx, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-devx.flakeModules.languages-go
        nix-devx.flakeModules.ai-claude
      ];

      perSystem = { config, pkgs, ... }: {
        languages.go.enable = true;
        ai.claude.enable = true;

        devShells.default = pkgs.mkShellNoCC {
          inputsFrom = [ config.devShells.go config.devShells.claude ];
        };
      };
    };
}
```

### From a Template

```bash
# Create a new Go project
nix flake init -t github:screwyprof/nix-devx#go

# Create a new Rust project
nix flake init -t github:screwyprof/nix-devx#rust

# Create a Claude Code project
nix flake init -t github:screwyprof/nix-devx#claude
```

## Available Modules

| Module | Description |
|--------|-------------|
| `languages-go` | Go toolchain with linting |
| `languages-rust` | Rust toolchain with cargo extensions |
| `languages-nix` | Nix formatting and linting |
| `ai-claude` | Claude Code integration |
| `ai-bmad-method` | BMad Method framework |

## Documentation

- **[Modules Reference](docs/modules.md)** - All modules, options, and usage
- **[Templates](docs/templates.md)** - Available templates and customization
- **[Dev Container Patterns](docs/devcontainer.md)** - Host vs container setup

## Developing This Repo

This repo uses its own modules for development.

### Dev Container

```bash
# Open in VS Code and run:
Dev Containers: Reopen in Container
```

### Host

```bash
nix develop
# or with direnv
direnv allow
```

## Philosophy

1. **Modular**: Use any combination of modules
2. **Lazy**: Disabled modules don't evaluate dependencies
3. **Independent**: Modules don't depend on each other
4. **Stackable**: Combine devShells via `inputsFrom`
