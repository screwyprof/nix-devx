{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  boolToBin = b: if b then "1" else "0";
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.ai.claude;
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
          type = types.str;
          default = "https://api.anthropic.com";
          description = "Anthropic API base URL";
        };

        models = mkOption {
          default = { };
          type = types.submodule {
            options = {
              default = mkOption {
                type = types.str;
                default = "claude-sonnet-4-20250514";
                description = "Default Claude model to use";
              };

              opus = mkOption {
                type = types.str;
                default = "claude-opus-4-20250514";
                description = "Opus model to use";
              };

              sonnet = mkOption {
                type = types.str;
                default = "claude-sonnet-4-20250514";
                description = "Sonnet model to use";
              };

              haiku = mkOption {
                type = types.str;
                default = "claude-haiku-4-20250514";
                description = "Haiku model to use";
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
          description = "Claude config directory path (null for default)";
        };

        tmpDir = mkOption {
          type = types.str;
          default = "/tmp/claude";
          description = "Claude temporary directory";
        };
      };

      config = mkIf cfg.enable {
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

        devShells.claude = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            nodejs
            config.packages.claude-wrapper
          ];

          shellHook = ''
            PROJECT_ROOT=''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
            PROJECT_HASH=''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}

            export CLAUDE_CONFIG_DIR=''${CLAUDE_CONFIG_DIR:-${
              if cfg.configDir != null then
                cfg.configDir
              else
                "\${XDG_STATE_HOME:-$HOME/.local/state}/claude/$PROJECT_HASH"
            }}
            mkdir -p "$CLAUDE_CONFIG_DIR"

            if [ -z "''${ANTHROPIC_AUTH_TOKEN:-}" ]; then
              echo "⚠️  Warning: ANTHROPIC_AUTH_TOKEN is not set"
            fi

            export ANTHROPIC_BASE_URL=''${ANTHROPIC_BASE_URL:-${cfg.baseUrl}}
            export ANTHROPIC_MODEL=''${ANTHROPIC_MODEL:-${cfg.models.default}}
            export ANTHROPIC_DEFAULT_OPUS_MODEL=''${ANTHROPIC_DEFAULT_OPUS_MODEL:-${cfg.models.opus}}
            export ANTHROPIC_DEFAULT_SONNET_MODEL=''${ANTHROPIC_DEFAULT_SONNET_MODEL:-${cfg.models.sonnet}}
            export ANTHROPIC_DEFAULT_HAIKU_MODEL=''${ANTHROPIC_DEFAULT_HAIKU_MODEL:-${cfg.models.haiku}}

            export DISABLE_TELEMETRY=''${DISABLE_TELEMETRY:-${boolToBin cfg.telemetry.disable}}
            export DISABLE_ERROR_REPORTING=''${DISABLE_ERROR_REPORTING:-${boolToBin cfg.telemetry.disableErrorReporting}}
            export DISABLE_AUTOUPDATER=''${DISABLE_AUTOUPDATER:-${boolToBin cfg.telemetry.disableAutoUpdater}}
            export DISABLE_INSTALLATION_CHECKS=''${DISABLE_INSTALLATION_CHECKS:-${boolToBin cfg.telemetry.disableInstallationChecks}}
            export IS_DEMO=''${IS_DEMO:-${boolToBin cfg.demo}}
            export CLAUDE_CODE_ENABLE_TELEMETRY=''${CLAUDE_CODE_ENABLE_TELEMETRY:-${boolToBin cfg.telemetry.enableClaudeCodeTelemetry}}
            export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=''${CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY:-${boolToBin cfg.telemetry.disableFeedbackSurvey}}
            export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=''${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:-${boolToBin cfg.telemetry.disableNonessentialTraffic}}

            export CLAUDE_CODE_SKIP_AUTH_LOGIN=''${CLAUDE_CODE_SKIP_AUTH_LOGIN:-${boolToBin cfg.ide.skipAuthLogin}}
            export CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL=''${CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL:-${boolToBin cfg.ide.skipAutoInstall}}

            export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=''${CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR:-${boolToBin cfg.shell.maintainProjectWorkingDir}}
            export CLAUDE_CODE_SHELL=''${CLAUDE_CODE_SHELL:-${cfg.shell.program}}

            export CLAUDE_CODE_TMPDIR=''${CLAUDE_CODE_TMPDIR:-${cfg.tmpDir}}

            echo "🤖 Claude Code Development Environment"
            echo "======================================"
            echo "Claude version: $(claude -v 2>/dev/null || echo unknown)"
            echo "PROJECT_ROOT: $PROJECT_ROOT"
            echo "CLAUDE_CONFIG_DIR: $CLAUDE_CONFIG_DIR"
            echo ""
          '';
        };
      };
    }
  );
}
