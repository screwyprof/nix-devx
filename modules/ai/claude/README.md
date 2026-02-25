# Claude Code Flake Module

A reusable flake-parts module for Claude Code integration. Provides configurable options for all Claude environment variables, MCP servers, and dev shell setup.

## Usage

In your project's `flake.nix`:

```nix
{
  description = "Test flake using the claude module as an external user";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-templates = {
      # For testing: use path:../.., for production: use github:screwyprof/nix-templates
      url = "path:../..";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      mcp-servers-nix,
      nix-templates,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          nix-templates.flakeModules.ai-claude
          mcp-servers-nix.flakeModule
        ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { system, ... }:
          {
            _module.args.pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            ai.claude = {
              enable = true;
              dangerouslySkipPermissions = true;
              baseUrl = "https://api.z.ai";
              models = {
                default = "glm-5";
                opus = "glm-4.7";
                sonnet = "glm-4.7";
                haiku = "glm-4.5-air";
              };
            };

            mcp-servers = {
              programs = {
                memory.enable = true;
                sequential-thinking.enable = true;
              };
              flavors.claude-code.enable = true;
            };
          };
      }
    );
}
```

## Configuration Options

### Claude Settings

- `claude.enable` (bool) - Enable Claude Code integration (default: false)
- `claude.baseUrl` (str) - Anthropic API base URL (default: "https://api.anthropic.com")
- `claude.models.default` (str) - Default Claude model (default: "claude-sonnet-4-20250514")
- `claude.models.opus` (str) - Opus model (default: "claude-opus-4-20250514")
- `claude.models.sonnet` (str) - Sonnet model (default: "claude-sonnet-4-20250514")
- `claude.models.haiku` (str) - Haiku model (default: "claude-haiku-4-20250514")

### Telemetry Settings

- `claude.telemetry.disable` (bool) - Disable Claude telemetry (default: false)
- `claude.telemetry.disableErrorReporting` (bool) - Disable error reporting (default: false)
- `claude.telemetry.disableAutoUpdater` (bool) - Disable auto updater (default: false)
- `claude.telemetry.disableInstallationChecks` (bool) - Disable installation checks (default: false)
- `claude.telemetry.enableClaudeCodeTelemetry` (bool) - Enable Claude Code telemetry (default: false)
- `claude.telemetry.disableFeedbackSurvey` (bool) - Disable feedback survey (default: true)
- `claude.telemetry.disableNonessentialTraffic` (bool) - Disable non-essential traffic (default: true)

### IDE Settings

- `claude.ide.skipAuthLogin` (bool) - Skip IDE auth login (default: false)
- `claude.ide.skipAutoInstall` (bool) - Skip IDE auto install (default: false)

### Bash Settings

- `claude.bash.maintainProjectWorkingDir` (bool) - Maintain project working directory (default: false)
- `claude.bash.shell` ("bash" | "zsh") - Shell for Claude Code (default: "bash")

### Other Settings

- `claude.demo` (bool) - Run in demo mode (default: false)
- `claude.configDir` (str | null) - Config directory (default: null, uses XDG_STATE_HOME)
- `claude.tmpDir` (str) - Temporary directory (default: "/tmp")

### MCP Servers Settings

The module includes `mcp-servers-nix` and exposes all its options:

- `mcp-servers.programs` - Configure MCP server programs
- `mcp-servers.flavors` - Configure per-flavor settings
- `mcp-servers.addGcRoot` - Add MCP config to GC roots (default: true)

See [mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix) for full documentation.

## Environment Variables

The following environment variables can be set externally to override Nix defaults:

- `ANTHROPIC_AUTH_TOKEN` - **Required** - Your Anthropic API token (not stored in Nix)
- `ANTHROPIC_BASE_URL` - API base URL override
- `ANTHROPIC_MODEL` - Default model override
- `ANTHROPIC_DEFAULT_OPUS_MODEL` - Opus model override
- `ANTHROPIC_DEFAULT_SONNET_MODEL` - Sonnet model override
- `ANTHROPIC_DEFAULT_HAIKU_MODEL` - Haiku model override
- `DISABLE_TELEMETRY` - Disable telemetry (1/0)
- `DISABLE_ERROR_REPORTING` - Disable error reporting (1/0)
- `DISABLE_AUTOUPDATER` - Disable auto updater (1/0)
- `DISABLE_INSTALLATION_CHECKS` - Disable installation checks (1/0)
- `IS_DEMO` - Demo mode (1/0)
- `CLAUDE_CODE_ENABLE_TELEMETRY` - Enable Claude Code telemetry (1/0)
- `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` - Disable feedback survey (1/0)
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` - Disable non-essential traffic (1/0)
- `CLAUDE_CODE_SKIP_AUTH_LOGIN` - Skip auth login (1/0)
- `CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL` - Skip auto install (1/0)
- `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` - Maintain working directory (1/0)
- `CLAUDE_CODE_SHELL` - Shell type (bash/zsh)
- `CLAUDE_CODE_TMPDIR` - Temporary directory

## Development Shell

The `config.devShells.claude` package provides a complete development shell with:
- `claude` binary in PATH
- All enabled MCP server packages
- Configured environment variables
- MCP config symlinks

Enter the shell with:
```bash
nix develop
```
