{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  # Claude reads these as SET-OR-NOT, not as a value: per the environment variable reference, "any
  # non-empty value including `0` turns the behavior on, and you turn the behavior off by unsetting the
  # variable". So a flag is either exported as `1` or absent — a rendered boolean cannot express "off".
  # The mapping layer this replaces rendered a nix `false` as the STRING "0", so every boolean it exposed
  # was inert (`telemetry.disable = false` could not re-enable telemetry) and `CLAUDE_CODE_ENABLE_TELEMETRY`
  # inverted its own meaning. Measured in a live shell before removal: all six exported as `0`.
  #
  # Delivered by shellHook rather than mkShell's `env`, which looks like the tidier home and is WRONG here:
  # both consumers compose this shell with `inputsFrom = [ config.ai.claude.devShell ]`, and mkShell merges
  # `shellHook` (an explicit `catAttrs "shellHook"`) while dropping `env`. Measured — with the flags in
  # `env` the banner still printed in the outer shell while every variable read `<unset>`.
  #
  # `$HOME/.claude` is Claude's OWN default, so the module does not export CLAUDE_CONFIG_DIR — it only
  # resolves one to seed. An external `export CLAUDE_CONFIG_DIR=…` (what devbox does per project, and the
  # supported way to get per-project config) therefore wins by simply being what Claude reads.
  claudeShellHook = ''
    export DISABLE_TELEMETRY=1
    export DISABLE_ERROR_REPORTING=1
    export DISABLE_AUTOUPDATER=1
    export DISABLE_INSTALLATION_CHECKS=1
    export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    export CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL=1

    claude_config_dir=''${CLAUDE_CONFIG_DIR:-$HOME/.claude}
    mkdir -p "$claude_config_dir"

    # Skip Claude's first-run onboarding/login wizard on a fresh config dir. `hasCompletedOnboarding`
    # is MUTABLE state Claude keeps in .claude.json (not policy — no env var or settings key flips it),
    # so seed it CREATE-IF-ABSENT: never clobber a real config, and the OAuth token still does the
    # actual auth (auth != onboarding).
    if [ ! -e "$claude_config_dir/.claude.json" ]; then
      printf '%s\n' '{"hasCompletedOnboarding":true}' > "$claude_config_dir/.claude.json"
    fi

    echo "🤖 Claude Code Development Environment loaded"
    echo "======================================"
    echo "Claude version: $(claude -v 2>/dev/null || echo unknown)"
    echo "CLAUDE_CONFIG_DIR: $claude_config_dir"
    echo ""
  '';
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

          shellHook = claudeShellHook;
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

          shellHook = claudeShellHook;
        };
      };
    }
  );
}
