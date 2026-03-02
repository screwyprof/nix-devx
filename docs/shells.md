# Dev Shells

Ad-hoc development shells for use in any project without creating a flake.

## Usage

```bash
# Enter a shell in any directory
cd any-project
nix develop "github:screwyprof/nix-devx?dir=shells/go"
```

## Available Shells

### go

Go development environment.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/go"
```

**Tools:** go, gopls, delve, golangci-lint, gofumpt, golines, gci

---

### rust

Rust development environment.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/rust"
```

**Tools:** rustc, cargo, bacon, cargo-edit, cargo-audit, cargo-nextest, cargo-watch

---

### nix

Nix development environment.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/nix"
```

**Tools:** nixfmt, statix, deadnix

---

### claude

Claude Code environment with MCP servers.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/claude"
```

**Tools:** Claude Code, MCP servers (memory, sequential-thinking)

**Note:** Requires `ANTHROPIC_AUTH_TOKEN` environment variable.

---

### bmad-method

BMad Method framework for AI-driven development.

```bash
nix develop "github:screwyprof/nix-devx?dir=shells/bmad-method"
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
