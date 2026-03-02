# nix-devx

Modular development environments with flake-parts.

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
      imports = [ nix-devx.flakeModules.languages-go ];

      perSystem = { config, pkgs, ... }: {
        languages.go.enable = true;

        devShells.default = pkgs.mkShellNoCC {
          inputsFrom = [ config.devShells.go ];
        };
      };
    };
}
```

### From a Template

```bash
nix flake init -t github:screwyprof/nix-devx#go
nix flake init -t github:screwyprof/nix-devx#rust
nix flake init -t github:screwyprof/nix-devx#claude
```

### Ad-hoc Dev Shells

Use a development shell in any project without creating a flake:

```bash
cd any-project
nix develop "github:screwyprof/nix-devx?dir=shells/go" --no-write-lock-file
```

> **Note:** Use `--no-write-lock-file` to prevent Nix from trying to write a lock file for remote flakes.

## Modules

| Module | Description |
|--------|-------------|
| `languages-go` | Go toolchain with linting |
| `languages-rust` | Rust toolchain with cargo extensions |
| `languages-nix` | Nix formatting and linting |
| `ai-claude` | Claude Code integration |
| `ai-bmad-method` | BMad Method framework |

## Documentation

- **[Modules Reference](docs/modules.md)** - All modules and options
- **[Templates](docs/templates.md)** - Available templates
- **[Dev Shells](docs/shells.md)** - Ad-hoc dev environments
- **[Dev Container Patterns](docs/devcontainer.md)** - Host vs container setup

## Philosophy

**Versatile by design.** Pick your setup at every level:

- **Host or container?** Your choice
- **direnv or nix develop?** Your choice
- **Which modules?** Mix and match any combination
- **How to stack?** Combine devShells via `inputsFrom`

Dev containers can be customized via docker-compose overrides. direnv can be customized per-user via `.envrc` (not committed). This repo uses nix on host for secret injection only, and activates the flake inside the container - but you can do it differently.

### Architecture

This project follows the **[flake-parts](https://github.com/hercules-ci/flake-parts)** + **[nix-dendritic](https://github.com/blake-perrott/nix-dendritic)** pattern:

- **flake-parts** provides composable flake modules with per-system configuration
- **nix-dendritic** pattern emphasizes modular, importable flake outputs

Each module is self-contained and can be imported independently, making it easy to mix and match language tooling, AI integrations, and development workflows.
