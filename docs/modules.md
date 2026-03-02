# Modules Reference

nix-devx provides flake-parts modules for development environments. Import them in your flake:

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
        nix-devx.flakeModules.languages-rust
        nix-devx.flakeModules.languages-nix
        nix-devx.flakeModules.ai-claude
        nix-devx.flakeModules.ai-bmad-method
      ];
      # ...
    };
}
```

## Language Modules

### languages-go

Go development environment with tooling and optional pre-commit hooks.

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `languages.go.enable` | bool | false | Enable Go language tooling |
| `languages.go.gobin` | nullOr str | null | Go bin directory (null for per-project) |
| `languages.go.gopath` | str | `$XDG_DATA_HOME/go` | Go path for module cache |
| `languages.go.hooks` | bool | false | Enable recommended git hooks |

**Provides:**
- `devShells.go` - Go development shell

**Included tools:** go, gopls, delve, gotools, golangci-lint, gofumpt, golines, gci

**Usage:**

```nix
perSystem = { config, ... }: {
  languages.go.enable = true;
  languages.go.hooks = true;

  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.go ];
  };
};
```

---

### languages-rust

Rust development environment with cargo extensions and optional pre-commit hooks.

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `languages.rust.enable` | bool | false | Enable Rust language tooling |
| `languages.rust.cargoHome` | nullOr str | null | Cargo home directory (null for per-project) |
| `languages.rust.toolchain` | nullOr package | null | Rust toolchain package (null for default) |
| `languages.rust.hooks` | bool | false | Enable recommended git hooks |

**Provides:**
- `devShells.rust` - Rust development shell

**Included tools:** rustc, cargo, bacon, cargo-edit, cargo-audit, cargo-binutils, cargo-nextest, cargo-watch, lcov, checkmake

**Usage:**

```nix
perSystem = { config, ... }: {
  languages.rust.enable = true;
  languages.rust.hooks = true;

  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.rust ];
  };
};
```

---

### languages-nix

Nix development environment with formatting and linting tools.

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `languages.nix.enable` | bool | false | Enable Nix language tooling |
| `languages.nix.hooks` | bool | false | Enable recommended git hooks |

**Provides:**
- `devShells.nix` - Nix development shell
- `formatter` - nixfmt-tree

**Included tools:** nixfmt, statix, deadnix

**Pre-commit hooks:** nixfmt, statix, deadnix, nil, flake-checker

**Usage:**

```nix
perSystem = { config, ... }: {
  languages.nix.enable = true;
  languages.nix.hooks = true;

  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.nix ];
  };
};
```

---

## AI Modules

### ai-claude

Claude Code integration with configurable environment and MCP server support.

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ai.claude.enable` | bool | false | Enable Claude Code integration |
| `ai.claude.dangerouslySkipPermissions` | bool | false | Skip permission checks |
| `ai.claude.baseUrl` | str | `https://api.anthropic.com` | API base URL |
| `ai.claude.models.default` | str | `claude-sonnet-4-20250514` | Default model |
| `ai.claude.models.opus` | str | `claude-opus-4-20250514` | Opus model |
| `ai.claude.models.sonnet` | str | `claude-sonnet-4-20250514` | Sonnet model |
| `ai.claude.models.haiku` | str | `claude-haiku-4-20250514` | Haiku model |
| `ai.claude.telemetry.disable` | bool | false | Disable all telemetry |
| `ai.claude.telemetry.disableErrorReporting` | bool | false | Disable error reporting |
| `ai.claude.telemetry.disableAutoUpdater` | bool | false | Disable auto updater |
| `ai.claude.configDir` | nullOr str | null | Config directory (null for per-project) |
| `ai.claude.tmpDir` | str | `/tmp/claude` | Temporary directory |
| `ai.claude.shell.program` | str | `bash` | Shell for Claude Code |
| `ai.claude.shell.maintainProjectWorkingDir` | bool | true | Maintain project working directory |

**Provides:**
- `packages.claude-wrapper` - Claude Code wrapper script
- `devShells.claude` - Claude development shell (respects `dangerouslySkipPermissions`)
- `devShells.claude-unrestricted` - Claude shell with permissions always skipped

**Usage:**

```nix
perSystem = { config, pkgs, ... }: {
  # Claude Code requires unfree
  _module.args.pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  ai.claude = {
    enable = true;
    baseUrl = "https://api.anthropic.com";
  };

  # For host (with permission checks)
  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.claude ];
  };

  # For trusted environments (devcontainer, VM)
  devShells.container = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.claude-unrestricted ];
  };
};
```

---

### ai-bmad-method

BMad Method AI framework integration.

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ai.bmad-method.enable` | bool | false | Enable BMad Method |

**Provides:**
- `packages.bmad-method` - BMad Method package
- `devShells.bmad-method` - BMad Method shell

**Usage:**

```nix
perSystem = { config, ... }: {
  ai.bmad-method.enable = true;

  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [ config.devShells.bmad-method ];
  };
};
```

---

## Stacking Dev Shells

Combine multiple modules by stacking their devShells:

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

## Host vs Container Configuration

Use different shells for host and container environments:

```nix
perSystem = { config, pkgs, ... }: {
  languages.go.enable = true;
  ai.claude.enable = true;

  # Host shell - with permission checks
  devShells.default = pkgs.mkShellNoCC {
    inputsFrom = [
      config.devShells.go
      config.devShells.claude
    ];
  };

  # Container shell - unrestricted for trusted environment
  devShells.container = pkgs.mkShellNoCC {
    inputsFrom = [
      config.devShells.go
      config.devShells.claude-unrestricted
    ];
  };
};
```

Then in `.devcontainer/.envrc`:
```bash
use flake .#container
```
