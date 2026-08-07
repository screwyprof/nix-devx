# Claude Template

Claude Code development environment with nix-devx modules.

## Usage

```bash
nix flake init -t github:screwyprof/nix-devx#claude
```

## What's Included

- Claude Code with configurable wrapper
- MCP servers (memory, sequential-thinking)
- Claude's own global config directory (~/.claude), overridable per project via `CLAUDE_CONFIG_DIR`
- MCP servers included in devShell

## After Init

1. Set `ANTHROPIC_AUTH_TOKEN` environment variable
2. Run `direnv allow` or `nix develop`

## Configuration

### Per-Project Config Directory

By default Claude uses its own global config directory at `~/.claude`, which is what VS Code extensions
and other tools expect. To give a project its own, export `CLAUDE_CONFIG_DIR` — a project's `.envrc` is
the natural place:

```sh
export CLAUDE_CONFIG_DIR="$HOME/.local/state/claude/my-project"
```

The shell writes nothing unless that variable is set, so entering it never seeds state into an
unmanaged home. When it IS set, the directory is created and Claude's first-run onboarding is skipped
(create-if-absent — an existing config is never overwritten).

## Host vs Container

For devcontainers or other trusted environments, use the unrestricted shell:

```nix
devShells.default = pkgs.mkShellNoCC {
  inputsFrom = [ config.ai.claude.devShellUnrestricted ];
};
```

This allows Claude to run without permission prompts.
