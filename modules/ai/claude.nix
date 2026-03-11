{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    concatStringsSep
    concatMap
    getAttrFromPath
    ;

  # Environment variable mapping - co-located with options for easier maintenance
  envVarMappings = [
    {
      envVar = "ANTHROPIC_BASE_URL";
      path = [ "baseUrl" ];
    }
    {
      envVar = "ANTHROPIC_MODEL";
      path = [
        "models"
        "default"
      ];
    }
    {
      envVar = "ANTHROPIC_DEFAULT_OPUS_MODEL";
      path = [
        "models"
        "opus"
      ];
    }
    {
      envVar = "ANTHROPIC_DEFAULT_SONNET_MODEL";
      path = [
        "models"
        "sonnet"
      ];
    }
    {
      envVar = "ANTHROPIC_DEFAULT_HAIKU_MODEL";
      path = [
        "models"
        "haiku"
      ];
    }
    {
      envVar = "DISABLE_TELEMETRY";
      path = [
        "telemetry"
        "disable"
      ];
    }
    {
      envVar = "DISABLE_ERROR_REPORTING";
      path = [
        "telemetry"
        "disableErrorReporting"
      ];
    }
    {
      envVar = "DISABLE_AUTOUPDATER";
      path = [
        "telemetry"
        "disableAutoUpdater"
      ];
    }
    {
      envVar = "DISABLE_INSTALLATION_CHECKS";
      path = [
        "telemetry"
        "disableInstallationChecks"
      ];
    }
    {
      envVar = "CLAUDE_CODE_ENABLE_TELEMETRY";
      path = [
        "telemetry"
        "enableClaudeCodeTelemetry"
      ];
    }
    {
      envVar = "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY";
      path = [
        "telemetry"
        "disableFeedbackSurvey"
      ];
    }
    {
      envVar = "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC";
      path = [
        "telemetry"
        "disableNonessentialTraffic"
      ];
    }
    {
      envVar = "CLAUDE_CODE_SKIP_AUTH_LOGIN";
      path = [
        "ide"
        "skipAuthLogin"
      ];
    }
    {
      envVar = "CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL";
      path = [
        "ide"
        "skipAutoInstall"
      ];
    }
    {
      envVar = "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR";
      path = [
        "shell"
        "maintainProjectWorkingDir"
      ];
    }
    {
      envVar = "CLAUDE_CODE_SHELL";
      path = [
        "shell"
        "program"
      ];
    }
    {
      envVar = "IS_DEMO";
      path = [ "demo" ];
    }
    {
      envVar = "CLAUDE_CODE_TMPDIR";
      path = [ "tmpDir" ];
    }
    {
      envVar = "CLAUDE_PROJECT_ISOLATION";
      path = [ "enableProjectIsolation" ];
    }
    {
      envVar = "CLAUDE_CONFIG_DIR";
      path = [ "configDir" ];
      runtimeDefault = "$(if [ \"\${CLAUDE_PROJECT_ISOLATION:-0}\" = \"1\" ]; then echo \"\${XDG_STATE_HOME:-$HOME/.local/state}/claude/$PROJECT_HASH\"; else echo \"$HOME/.claude\"; fi)";
    }
  ];

  # Generate environment variable exports from mappings
  # Skips mappings where the value is null and no runtimeDefault is provided
  mkEnvExports =
    cfg: mappings:
    concatStringsSep "\n" (
      concatMap (
        mapping:
        let
          configValue = getAttrFromPath mapping.path cfg;
        in
        if configValue == null && !(mapping ? runtimeDefault) then
          [ ]
        else
          let
            convertedValue =
              if configValue == null then
                mapping.runtimeDefault
              else if builtins.isBool configValue then
                (if configValue then "1" else "0")
              else
                toString configValue;
          in
          [ "export ${mapping.envVar}=\${${mapping.envVar}:-${convertedValue}}" ]
      ) mappings
    );
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.ai.claude;

      # Shared shellHook for Claude shells
      mkClaudeShellHook = cfg: ''
        PROJECT_ROOT=''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
        PROJECT_HASH=''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}

        # Auto-generated environment variable exports
        ${mkEnvExports cfg envVarMappings}

        # Create config directory
        mkdir -p "$CLAUDE_CONFIG_DIR"

        echo "🤖 Claude Code Development Environment loaded"
        echo "======================================"
        echo "Claude version: $(claude -v 2>/dev/null || echo unknown)"
        echo "PROJECT_ROOT: $PROJECT_ROOT"
        echo "CLAUDE_CONFIG_DIR: $CLAUDE_CONFIG_DIR"
        echo ""
      '';
    in
    {
      options.ai.claude = {
        enable = mkEnableOption "Claude Code integration";

        dangerouslySkipPermissions = mkOption {
          type = types.bool;
          default = false;
          description = "Skip permission checks in Claude Code wrapper";
        };

        baseUrl = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Anthropic API base URL (null to use Claude's default)";
        };

        models = mkOption {
          default = { };
          type = types.submodule {
            options = {
              default = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Default Claude model to use (null to use Claude's default)";
              };

              opus = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Opus model to use (null to use Claude's default)";
              };

              sonnet = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Sonnet model to use (null to use Claude's default)";
              };

              haiku = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Haiku model to use (null to use Claude's default)";
              };
            };
          };
          description = "Model configurations";
        };

        telemetry = mkOption {
          default = { };
          type = types.submodule {
            options = {
              disable = mkOption {
                type = types.bool;
                default = false;
                description = "Disable all telemetry";
              };

              disableErrorReporting = mkOption {
                type = types.bool;
                default = false;
                description = "Disable error reporting";
              };

              disableAutoUpdater = mkOption {
                type = types.bool;
                default = false;
                description = "Disable auto updater";
              };

              disableInstallationChecks = mkOption {
                type = types.bool;
                default = false;
                description = "Disable installation checks";
              };

              enableClaudeCodeTelemetry = mkOption {
                type = types.bool;
                default = false;
                description = "Enable Claude Code telemetry";
              };

              disableFeedbackSurvey = mkOption {
                type = types.bool;
                default = false;
                description = "Disable feedback survey";
              };

              disableNonessentialTraffic = mkOption {
                type = types.bool;
                default = false;
                description = "Disable nonessential traffic";
              };
            };
          };
          description = "Telemetry settings";
        };

        ide = mkOption {
          default = { };
          type = types.submodule {
            options = {
              skipAuthLogin = mkOption {
                type = types.bool;
                default = false;
                description = "Skip auth login in IDE";
              };

              skipAutoInstall = mkOption {
                type = types.bool;
                default = false;
                description = "Skip auto install in IDE";
              };
            };
          };
          description = "IDE settings";
        };

        shell = mkOption {
          default = { };
          type = types.submodule {
            options = {
              maintainProjectWorkingDir = mkOption {
                type = types.bool;
                default = true;
                description = "Maintain project working directory";
              };

              program = mkOption {
                type = types.str;
                default = "bash";
                description = "Shell program to use for Claude Code";
              };
            };
          };
          description = "Shell settings";
        };

        demo = mkOption {
          type = types.bool;
          default = false;
          description = "Run in demo mode";
        };

        configDir = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Claude config directory path. Defaults to ~/.claude globally, or per-project if isolation enabled";
        };

        enableProjectIsolation = mkOption {
          type = types.bool;
          default = false;
          description = "Enable per-project config isolation (advanced users only)";
        };

        tmpDir = mkOption {
          type = types.str;
          default = "/tmp/claude";
          description = "Claude temporary directory";
        };

        devShell = mkOption {
          type = types.package;
          readOnly = true;
          description = "Claude Code development shell (respects dangerouslySkipPermissions)";
        };

        devShellUnrestricted = mkOption {
          type = types.package;
          readOnly = true;
          description = "Claude Code development shell (always skips permissions)";
        };
      };

      config = mkIf cfg.enable {
        # Main wrapper respects the dangerouslySkipPermissions config
        packages.claude-wrapper = pkgs.writeShellApplication {
          name = "claude";
          runtimeInputs = [ pkgs.claude-code ];

          text =
            if cfg.dangerouslySkipPermissions then
              ''
                exec ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
              ''
            else
              ''
                exec ${pkgs.claude-code}/bin/claude "$@"
              '';
        };

        # Main devShell - respects dangerouslySkipPermissions config
        ai.claude.devShell = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            nodejs
            config.packages.claude-wrapper
          ];

          shellHook = mkClaudeShellHook cfg;
        };

        # Unrestricted devShell - always skips permissions
        # Use this for trusted environments like devcontainers
        ai.claude.devShellUnrestricted = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            nodejs
            (pkgs.writeShellApplication {
              name = "claude";
              runtimeInputs = [ pkgs.claude-code ];
              text = ''
                exec ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
              '';
            })
          ];

          shellHook = mkClaudeShellHook cfg;
        };
      };
    }
  );
}
