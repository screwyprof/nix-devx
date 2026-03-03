{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    optionalAttrs
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
    in
    {
      options.languages.nix = {
        enable = mkEnableOption "Nix language tooling";

        hooks = mkEnableOption "recommended git hooks for Nix";
      };

      config = mkIf cfg.enable (mkMerge [
        {
          formatter = pkgs.nixfmt-tree;

          # Nix devShell
          devShells.nix = pkgs.mkShellNoCC {
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
