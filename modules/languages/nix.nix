{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.languages.nix;
    in
    {
      options.languages.nix = {
        enable = mkEnableOption "Nix language tooling";

        hooks = mkEnableOption "recommended git hooks for Nix";
      };

      config = mkIf cfg.enable {
        formatter = pkgs.nixfmt-tree;

        # Configure git hooks (only if hooks.enable is true)
        pre-commit.settings.hooks = mkIf cfg.hooks {
          nixfmt.enable = true;
          statix.enable = true;
          deadnix = {
            enable = true;
            settings.noLambdaPatternNames = true;
          };
          nil.enable = true;
          flake-checker.enable = true;
        };

        # Nix devShell
        devShells.nix = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            nixfmt
            statix
            deadnix
          ];

          shellHook = ''
            echo "🔧 Nix development environment loaded"
            echo "Formatter: nixfmt"
            echo "Linter: statix"
            echo "Dead code finder: deadnix"
            echo ""
          '';
        };
      };
    }
  );
}
