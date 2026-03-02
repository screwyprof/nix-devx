# Claude Template

Claude Code development environment with nix-devx modules.

## Usage

```bash
nix flake init -t github:screwyprof/nix-devx#claude
```

## What's Included

- Claude Code with configurable wrapper
- MCP servers (memory, sequential-thinking)
- Per-project config directory isolation
- Two devShells:
  - `claude` - respects `dangerouslySkipPermissions` config
  - `claude-unrestricted` - always skips permissions (for trusted environments)

## After Init

1. Set `ANTHROPIC_AUTH_TOKEN` environment variable
2. Run `direnv allow` or `nix develop`

## Host vs Container

For devcontainers or other trusted environments, use the unrestricted shell:

```nix
devShells.default = pkgs.mkShellNoCC {
  inputsFrom = [ config.devShells.claude-unrestricted ];
};
```

This allows Claude to run without permission prompts.
