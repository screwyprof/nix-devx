# Claude Template

Claude Code development environment with nix-devx modules.

## Usage

```bash
nix flake init -t github:screwyprof/nix-devx#claude
```

## What's Included

- Claude Code with configurable wrapper
- MCP servers (memory, sequential-thinking)
- Global config directory (~/.claude) with opt-in per-project isolation
- MCP servers included in devShell

## After Init

1. Set `ANTHROPIC_AUTH_TOKEN` environment variable
2. Run `direnv allow` or `nix develop`

## Configuration

### Per-Project Isolation (Advanced)

By default, Claude uses a global config directory at `~/.claude` for compatibility with VS Code extensions and other tools. To enable per-project isolation:

```nix
perSystem.ai.claude.enableProjectIsolation = true;
```

This creates isolated config directories at `~/.local/state/claude/<project-hash>` for each project.

## Host vs Container

For devcontainers or other trusted environments, use the unrestricted shell:

```nix
devShells.default = pkgs.mkShellNoCC {
  inputsFrom = [ config.ai.claude.devShellUnrestricted ];
};
```

This allows Claude to run without permission prompts.
