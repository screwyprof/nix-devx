# Flexible Development Environment

An example project demonstrating a configurable dev environment. This setup supports multiple workflows without forcing any particular tooling choice.

## My Use Case

I run Claude Code and VS Code extensions inside a dev container (which itself runs in a VM) for isolation. On my host, VS Code is managed by Nix with minimal trusted extensions with all settings in read only mode. Nix also manages my secrets and dev tooling.

## Philosophy

This is an **example** of how to set up a flexible dev environment. The key idea is providing choice:

- Host or container? Your choice
- Direnv or manual? Your choice
- `.envrc` or `.env`? Your choice

## Quick Start

### Dev Container

1. Set `ANTHROPIC_AUTH_TOKEN` in your environment
2. Open in VS Code and run `Dev Containers: Reopen in Container`

That's it! Nix and direnv inside the container handle everything.

[VS Code Dev Container documentation](https://code.claude.com/docs/en/devcontainer) | [Claude Code Dev Container](https://code.claude.com/docs/en/devcontainer)

### Optional: Inject Secrets via Direnv

If you use direnv, you can create `.envrc` to inject secrets using your password manager or secrets manager (sops, 1password, etc.). See `.envrc.template` for examples.

### Optional: Inject Secrets via `.env` File

Alternatively, create a `.env` file in the project root (git-ignored). The docker-compose override will auto-load it:

```bash
# .env
ANTHROPIC_AUTH_TOKEN=sk-ant-...
```

> **Note**: For better security practices, consider using a password/secret manager to retrieve secrets (see direnv examples above).

### Optional: Shift+Enter in Terminal (macOS)

On macOS, if you want `Shift+Enter` to create a newline in terminals (for multi-line input), add this to your Mac's VSCode keybindings (`Cmd+Shift+P` → "Preferences: Open Keyboard Shortcuts (JSON)"):

```json
[
  {
    "key": "shift+enter",
    "command": "workbench.action.terminal.sendSequence",
    "args": { "text": "\\u001B\\u000A" },
    "when": "terminalFocus"
  }
]
```

### Optional: Use Nix on Host

If you have Nix, you know what to do: `nix develop` or add `use flake .` to your `.envrc`.

## Configuration

Templates available for customization:

| Template | Creates | Purpose |
|----------|---------|---------|
| `.envrc.template` | `.envrc` | Example for host secret injection (customize as needed) |
| `.devcontainer/.envrc.template` | `.devcontainer/.envrc` | Container-specific, auto-copied on first open |
| `.devcontainer/docker-compose.override.template.yml` | `.devcontainer/docker-compose.override.yml` | Container-specific, auto-copied on first open |

### Host vs Container Separation

You can have completely different behavior in each environment:

**Host `.envrc`** - Secret injection only:
```bash
# No use flake . here - just inject secrets
if has sops; then
  export ANTHROPIC_AUTH_TOKEN=$(sops -d --extract '["service"]["api_key"]' ~/path/to/secrets.yaml)
fi
```

**Container `.envrc`** - Has `use flake .`, no secrets:
```bash
use flake .
```

## Nix flake Claude Code Integration

Includes MCP servers:
- **context7** - Library documentation
- **memory** - Knowledge graph
- **sequential-thinking** - Structured problem solving
- **serena** - Semantic code navigation
