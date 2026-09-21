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

    # WRITES ONLY WHERE IT HAS BEEN TOLD TO. Entering a devShell must not create or seed state in the
    # user's real home — before this, an unset CLAUDE_CONFIG_DIR defaulted to `$HOME/.claude` and the
    # hook did `mkdir -p` + wrote `.claude.json` there, so merely entering the shell side-effected the
    # workstation's home. Seeding is for a config dir the CONSUMER pointed somewhere deliberate (devbox
    # sets it per project); with it unset, Claude uses its own `~/.claude` and runs its own onboarding,
    # which is the user's business and not a shell hook's.
    if [ -n "''${CLAUDE_CONFIG_DIR:-}" ]; then
      mkdir -p "$CLAUDE_CONFIG_DIR"

      # Skip Claude's first-run onboarding/login wizard on a fresh config dir. `hasCompletedOnboarding`
      # is MUTABLE state Claude keeps in .claude.json (not policy — no env var or settings key flips
      # it), so seed it CREATE-IF-ABSENT: never clobber a real config, and the OAuth token still does
      # the actual auth (auth != onboarding).
      if [ ! -e "$CLAUDE_CONFIG_DIR/.claude.json" ]; then
        printf '%s\n' '{"hasCompletedOnboarding":true}' > "$CLAUDE_CONFIG_DIR/.claude.json"
      fi
    fi

    echo "🤖 Claude Code Development Environment loaded"
    echo "======================================"
    echo "Claude version: $(claude -v 2>/dev/null || echo unknown)"
    # No apostrophe in the fallback: inside `''${VAR:-word}` a lone `'` opens a quote bash never closes,
    # and the whole hook dies with "unexpected EOF while looking for matching `'`".
    echo "CLAUDE_CONFIG_DIR: ''${CLAUDE_CONFIG_DIR:-(unset, Claude uses its own default)}"
    echo ""
  '';
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.ai.claude;

      # ONE body, because the two behaviours differ by a single flag. Before this there were three
      # wrapper bodies for two behaviours, and `cfg.package` appeared in five places — the pairing is
      # what made that a hazard rather than clutter: inside each wrapper `runtimeInputs` puts a `claude`
      # on PATH while the `exec` names an absolute store path, so touching one and not the other yields a
      # shell where `claude` and whatever resolves it off PATH are DIFFERENT builds, with no error.
      mkClaude =
        skipPermissions:
        pkgs.writeShellApplication {
          name = "claude";
          runtimeInputs = [ cfg.package ];
          text = ''
            exec ${cfg.package}/bin/claude ${lib.optionalString skipPermissions "--dangerously-skip-permissions "}"$@"
          '';
        };
    in
    {
      options.ai.claude = {
        enable = mkEnableOption "Claude Code integration";

        dangerouslySkipPermissions = mkOption {
          type = types.bool;
          default = false;
          description = "Skip permission checks in Claude Code wrapper";
        };

        # No vendored manifest. This used to default to
        # `pkgs.claude-code.override { manifest = ./claude-manifest.json; }` to run ahead of a lagging
        # channel, which worked until nixpkgs kept the argument named `manifest` while changing what it
        # must contain (`manifest.json` + `installBin` -> `manifest.zst.json` + `unzstd`). Consumers set
        # `inputs.nixpkgs.follows`, so a manifest vendored here always meets a nixpkgs of a different
        # era, and the mismatch cannot fail at eval — only in installPhase, on their lock bump.
        #
        # The pin also bought nothing anymore: nixpkgs' update.sh follows the `latest` channel.
        # If a future lag justifies pinning, set this option in the CONSUMER, where the manifest and the
        # nixpkgs reading it are locked together.
        package = mkOption {
          type = types.package;
          default = pkgs.claude-code;
          defaultText = lib.literalExpression "pkgs.claude-code";
          description = "The claude-code package the wrapper and both devShells run.";
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
        packages.claude-wrapper = mkClaude cfg.dangerouslySkipPermissions;

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
            (mkClaude true)
          ];

          shellHook = claudeShellHook;
        };
      };
    }
  );
}
