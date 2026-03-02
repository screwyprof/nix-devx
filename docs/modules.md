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

**Provides:** `devShells.go`

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

**Provides:** `devShells.rust`

**Tools:** rustc, cargo, bacon, cargo-edit, cargo-audit, cargo-nextest, cargo-watch, lcov

**Hooks:** rustfmt, cargo-check, clippy

---

### languages-nix

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Nix tooling |
| `hooks` | bool | false | Enable pre-commit hooks |

**Provides:** `devShells.nix`, `formatter`

**Tools:** nixfmt, statix, deadnix

**Hooks:** nixfmt, statix, deadnix, nil, flake-checker

---

## AI Modules

### ai-claude

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Claude Code |
| `dangerouslySkipPermissions` | bool | false | Skip permission checks |
| `baseUrl` | str | `https://api.anthropic.com` | API base URL |
| `models.default` | str | `claude-sonnet-4-20250514` | Default model |

**Provides:**
- `packages.claude-wrapper`
- `devShells.claude` - respects `dangerouslySkipPermissions`
- `devShells.claude-unrestricted` - always skips permissions

**Note:** Claude Code requires `allowUnfree = true`. Telemetry is disabled by default.

See [devcontainer.md](devcontainer.md) for host vs container setup with unrestricted mode.

---

### ai-bmad-method

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable BMad Method |

**Provides:** `packages.bmad-method`, `devShells.bmad-method`

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
      config.devShells.go
      config.devShells.nix
      config.devShells.claude
    ];
  };
};
```
