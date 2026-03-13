{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    types
    ;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      options,
      ...
    }:
    let
      cfg = config.languages.nix;
      hasPreCommit = options ? pre-commit;
      hasTreefmt = options ? treefmt;
    in
    {
      options.languages.nix = {
        enable = mkEnableOption "Nix language tooling";

        formatters = mkEnableOption "recommended treefmt formatters for Nix";

        hooks = mkEnableOption "recommended git hooks for Nix";

        devShell = mkOption {
          type = types.package;
          readOnly = true;
          description = "Nix development shell";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          # Nix devShell
          languages.nix.devShell = pkgs.mkShellNoCC {
            nativeBuildInputs = with pkgs; [
              nixfmt
              statix
              deadnix
            ];

            shellHook = ''
              echo "Nix development environment loaded"
              echo "Formatter: nixfmt"
              echo "Linter: statix"
              echo "Dead code finder: deadnix"
              echo ""
            '';
          };
        }
        # Fallback formatter when treefmt module is not loaded
        (optionalAttrs (!hasTreefmt) {
          formatter = pkgs.nixfmt-tree;
        })
        # treefmt formatters (only if treefmt module is loaded)
        (optionalAttrs hasTreefmt {
          treefmt.programs = mkIf cfg.formatters {
            nixfmt.enable = true;
          };
        })
        (optionalAttrs hasPreCommit {
          # Configure git hooks (only if hooks.enable is true AND pre-commit module is loaded)
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
        })
      ]);
    }
  );
}
