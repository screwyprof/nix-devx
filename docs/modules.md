# Modules Reference

nix-devx provides flake-parts modules for development environments.

```nix
{
  inputs = {
    nix-devx.url = "github:screwyprof/nix-devx";
    nix-devx.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, nix-devx, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-devx.flakeModules.languages-go
        nix-devx.flakeModules.ai-claude
      ];
      # ...
    };
}
```

## Language Modules

### languages-go

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Go tooling |
| `hooks` | bool | false | Enable pre-commit hooks |
| `gobin` | nullOr str | null | GOBIN directory (null for per-project) |
| `gopath` | str | `$XDG_DATA_HOME/go` | GOPATH for module cache |

**Provides:** `languages.go.devShell`

**Tools:** go, gopls, delve, gotools, golangci-lint, gofumpt, golines, gci

**Hooks:** golangci-lint

---

### languages-rust

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Rust tooling |
| `hooks` | bool | false | Enable pre-commit hooks |
| `cargoHome` | nullOr str | null | CARGO_HOME (null for per-project) |
| `toolchain` | nullOr package | null | Custom toolchain |

**Provides:** `languages.rust.devShell`

**Tools:** rustc, cargo, bacon, cargo-edit, cargo-audit, cargo-nextest, cargo-watch, lcov

**Hooks:** rustfmt, cargo-check, clippy

---

### languages-nix

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Nix tooling |
| `hooks` | bool | false | Enable pre-commit hooks |

**Provides:** `languages.nix.devShell`, `formatter`

**Tools:** nixfmt, statix, deadnix

**Hooks:** nixfmt, statix, deadnix, nil, flake-checker

---

## AI Modules

### ai-claude

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Claude Code |
| `dangerouslySkipPermissions` | bool | false | Skip permission checks |

**Provides:**
- `packages.claude-wrapper`
- `ai.claude.devShell` - respects `dangerouslySkipPermissions`
- `ai.claude.devShellUnrestricted` - always skips permissions

**Config directory:** set `CLAUDE_CONFIG_DIR` in the environment (a project's `.envrc` is the usual
place). The module does not set it — unset means Claude uses its own `~/.claude`. It also writes
nothing unless that variable is set, so entering the shell never seeds state in an unmanaged home.

**Telemetry** is disabled unconditionally: Claude reads these flags as set-or-not, so a value of `0`
would turn the behaviour ON rather than off, and there is no way to express "off" other than omitting
the variable. They are therefore not configurable.

**Note:** Claude Code requires `allowUnfree = true`.

See [devcontainer.md](devcontainer.md) for host vs container setup with unrestricted mode.

---

### ai-bmad-method

BMad Method is an AI-driven agile development framework with 12+ specialized agents
(PM, Architect, Developer, UX, Scrum Master, etc.) and 34+ workflows for the complete
software development lifecycle.

- **GitHub:** https://github.com/bmad-code-org/BMAD-METHOD
- **Documentation:** https://docs.bmad-method.org
- **npm:** https://www.npmjs.com/package/bmad-method

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable BMad Method |

**Provides:** `packages.bmad-method`, `ai.bmad-method.devShell`

---

## Stacking Dev Shells

Combine modules by stacking their devShells:

```nix
perSystem = { config, pkgs, ... }: {
  languages.go.enable = true;
  languages.nix.enable = true;
  ai.claude.enable = true;

  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [
      config.languages.go.devShell
      config.languages.nix.devShell
      config.ai.claude.devShell
    ];
  };
};
```
