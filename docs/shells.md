# Dev Shells

Ad-hoc development shells for use in any project without creating a flake.

## Usage

```bash
# Enter a shell in any directory
cd any-project
nix develop "github:screwyprof/nix-devx?dir=shells/go" --no-write-lock-file
```

> **Note:** Use `--no-write-lock-file` to prevent Nix from trying to write a lock file for remote flakes.

## Available Shells

### go

Go development environment.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/go" --no-write-lock-file
```

**Tools:** go, gopls, delve, golangci-lint, gofumpt, golines, gci

---

### rust

Rust development environment.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/rust" --no-write-lock-file
```

**Tools:** rustc, cargo, bacon, cargo-edit, cargo-audit, cargo-nextest, cargo-watch

---

### nix

Nix development environment.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/nix" --no-write-lock-file
```

**Tools:** nixfmt, statix, deadnix

---

### claude

Claude Code environment with MCP servers (restricted — respects permissions).

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/claude" --no-write-lock-file
```

**Tools:** Claude Code, MCP servers (memory, sequential-thinking)

**Note:** Requires `ANTHROPIC_AUTH_TOKEN` environment variable.

---

### claude-unrestricted

Claude Code environment with MCP servers (skips permission checks — for trusted environments).

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/claude-unrestricted" --no-write-lock-file
```

**Tools:** Claude Code (unrestricted), MCP servers (memory, sequential-thinking)

**Note:** Requires `ANTHROPIC_AUTH_TOKEN` environment variable.

---

### bmad-method

BMad Method framework for AI-driven development.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/bmad-method" --no-write-lock-file
```

**Tools:** bmad-method CLI

**Links:** [GitHub](https://github.com/bmad-code-org/BMAD-METHOD) | [Docs](https://docs.bmad-method.org)

---

## When to Use Shells vs Templates

| Use Shells | Use Templates |
|------------|---------------|
| Working on an existing project | Starting a new project |
| Don't want to modify the project | Want to commit the flake.nix |
| Quick ad-hoc environment | Need pre-commit hooks |
| Testing or contributing to others' repos | Project-specific customization |

## Combining with direnv

For automatic shell activation, add to your project's `.envrc`:

```bash
use flake "github:screwyprof/nix-devx?dir=shells/go"
```

Or for local development, clone nix-devx and use:

```bash
use flake /path/to/nix-devx/shells/go
```
