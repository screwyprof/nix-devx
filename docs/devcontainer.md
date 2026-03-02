# Dev Container Setup

This project uses a dev container for isolated development. The setup is designed to be highly customizable.

## Key Concept: Host vs Container Separation

The same project can behave differently on host and in container:

| File | Host | Container |
|------|------|-----------|
| `.envrc` | Read by host direnv | Can be overridden |
| `.devcontainer/.envrc` | Ignored | Used if mounted |

This allows you to:
- Skip nix on host, use it only in container
- Use different devShells (`default` vs `container`)
- Run AI agents only in isolated environments

## The Override Pattern

The dev container uses Docker Compose with overrides:

```
.devcontainer/
├── docker-compose.yml                   # Base configuration
├── docker-compose.override.yml          # Your customizations (git-ignored)
├── docker-compose.override.template.yml # Minimal - copy to use
├── docker-compose.override.example.yml  # Reference - shows all options
├── .envrc                               # Container-specific envrc
└── .envrc.template                      # Template for container envrc
```

### How It Works

1. `devcontainer.json` loads both compose files:
   ```json
   "dockerComposeFile": [
     "docker-compose.yml",
     "docker-compose.override.yml"
   ]
   ```

2. The override file customizes behavior without modifying the base config

3. Example files show override patterns

### Creating Your Override

Two approaches:

**Quick start** - copy the template:
```bash
cp .devcontainer/docker-compose.override.template.yml .devcontainer/docker-compose.override.yml
```

**Custom setup** - use the example as reference:
```bash
cp .devcontainer/docker-compose.override.example.yml .devcontainer/docker-compose.override.yml
# Then edit to add/remove options
```

The example shows additional options like mounting a container-specific `.envrc`:

```yaml
# .devcontainer/docker-compose.override.yml
services:
  nix-devx:
    # Option 1: Load environment from .env file
    env_file:
      - path: ../.env
        required: false

    # Option 2: Mount container-specific .envrc
    volumes:
      - ./.envrc:/workspaces/.envrc:ro
```

**Important**: The volume mount replaces `/workspaces/.envrc` with `.devcontainer/.envrc` inside the container. If you enable this, edits to root `.envrc` won't affect the container.

### Templates vs Examples

| File | Type | Purpose |
|------|------|---------|
| `.envrc.template` | Template | Copy to `.envrc` - ready to use |
| `docker-compose.override.template.yml` | Template | Minimal - copy and use |
| `docker-compose.override.example.yml` | Example | Shows all options - reference |

## The `.envrc` Pattern

By default, the project's root `.envrc` is used in both host and container.

### Option 1: Same `.envrc` everywhere

Do nothing. Both host and container use the root `.envrc`.

### Option 2: Different `.envrc` for container

Create `.devcontainer/.envrc` with container-specific config:

```bash
# .devcontainer/.envrc
use flake .#container
```

Then add to your `docker-compose.override.yml`:

```yaml
services:
  nix-devx:
    volumes:
      - ./.envrc:/workspaces/.envrc:ro
```

This mounts `.devcontainer/.envrc` over `/workspaces/.envrc` inside the container.

### Typical Setup

**Root `.envrc`** (host):
```bash
# Empty or just secret injection - no nix on host
export ANTHROPIC_AUTH_TOKEN=$(sops -d ...)
```

**`.devcontainer/.envrc`** (container):
```bash
use flake .#container
```

## The Container Shell

nix-devx provides `devShells.claude-unrestricted` that skips Claude's permission checks. Use it in trusted environments like containers.

In your project's `flake.nix`, define a container-specific shell:

```nix
perSystem = { config, pkgs, ... }: {
  languages.go.enable = true;
  ai.claude.enable = true;

  # Host shell - with permission checks
  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.go config.devShells.claude ];
  };

  # Container shell - unrestricted for trusted environment
  devShells.container = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.go config.devShells.claude-unrestricted ];
  };
};
```

Then in `.devcontainer/.envrc`:
```bash
use flake .#container
```

You can name it anything - `container`, `devcontainer`, `unrestricted` - it's your project's shell.

## Environment Variables

Pass variables through `docker-compose.yml`:

```yaml
services:
  nix-devx:
    environment:
      - ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN}
      - ANTHROPIC_MODEL=${ANTHROPIC_MODEL:-claude-sonnet-4-20250514}
```

Set them in your shell before starting the container, or use a `.env` file loaded via override.

## This Repo's Setup

This repository (nix-devx itself) demonstrates the pattern:

- **Host**: Root `.envrc` is minimal (no nix)
- **Container**: Uses `.#container` shell (defined in this repo's `flake.nix`)
- **Override**: Mounts `.devcontainer/.envrc` over root `.envrc`

See `.devcontainer/` for the reference implementation. Note that `.#container` is this repo's own shell - you'll define your own in your project.
