{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
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

            export CLAUDE_CONFIG_DIR=''${CLAUDE_CONFIG_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/claude/$PROJECT_HASH}
            mkdir -p "$CLAUDE_CONFIG_DIR"

            if [ -z "''${ANTHROPIC_AUTH_TOKEN:-}" ]; then
              echo "⚠️  Warning: ANTHROPIC_AUTH_TOKEN is not set"
            fi

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
