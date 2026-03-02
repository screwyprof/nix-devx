# Dev Container Patterns

Use dev containers for isolated development. This guide shows the patterns - adapt them to your needs.

## The Pattern

```
your-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── docker-compose.yml
│   ├── docker-compose.override.yml          # Your customizations (git-ignored)
│   ├── docker-compose.override.template.yml # Minimal starting point
│   ├── docker-compose.override.example.yml  # Shows all options
│   ├── .envrc                               # Container-specific (git-ignored)
│   └── .envrc.template                      # Starting point
├── .envrc                                   # Host-specific (git-ignored)
└── flake.nix
```

## Key Concept

`.envrc` files are **not committed** - each user customizes their own setup:

- **Root `.envrc`** - Used on host
- **`.devcontainer/.envrc`** - Used in container (if mounted)

This lets you:
- Use nix on host only, container only, or both
- Inject secrets differently on host vs container
- Use different devShells in each environment

## Override Pattern

`devcontainer.json` loads both compose files:

```json
"dockerComposeFile": [
  "docker-compose.yml",
  "docker-compose.override.yml"
]
```

The override customizes behavior without modifying base config.

### Quick Start

```bash
cp .devcontainer/docker-compose.override.template.yml .devcontainer/docker-compose.override.yml
cp .devcontainer/.envrc.template .devcontainer/.envrc
```

### Full Customization

The example shows all options:

```yaml
# docker-compose.override.example.yml
services:
  your-service:
    env_file:
      - path: ../.env
        required: false
    volumes:
      - ./.envrc:/workspaces/.envrc:ro
```

**Warning:** The volume mount replaces `/workspaces/.envrc` with `.devcontainer/.envrc` inside the container.

## Example Setups

### Host: secrets only, Container: nix

**Root `.envrc`** (host):
```bash
# Just inject secrets, no nix
export ANTHROPIC_AUTH_TOKEN=$(sops -d ...)
```

**`.devcontainer/.envrc`** (container):
```bash
use flake .#container
```

### Same `.envrc` everywhere

Don't create `.devcontainer/.envrc`. Both use root `.envrc`:

```bash
use flake .
```

### Full nix on host too

```bash
# Root .envrc
use flake .
```

## Unrestricted Claude in Container

Define a container shell in your `flake.nix`:

```nix
perSystem = { config, pkgs, ... }: {
  ai.claude.enable = true;

  # Host - normal permissions
  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.claude ];
  };

  # Container - unrestricted
  devShells.container = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.claude-unrestricted ];
  };
};
```

Then in `.devcontainer/.envrc`:
```bash
use flake .#container
```

## Template vs Example

| File | Purpose |
|------|---------|
| `.template` | Copy and use as-is |
| `.example` | Reference to learn from |
