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
      cfg = config.ai.bmad-method;
    in
    {
      options.ai.bmad-method = {
        enable = mkEnableOption "BMad Method AI framework";
      };

      config = mkIf cfg.enable {
        packages.bmad-method = pkgs.callPackage ../../pkgs/bmad-method.nix { };

        devShells.bmad-method = pkgs.mkShellNoCC {
          nativeBuildInputs = [ config.packages.bmad-method ];

          shellHook = ''
            echo "🤖 BMad Method Development Environment"
            echo "======================================"
            bmad-method --version || echo "BMad Method not yet available"
            echo ""
            echo "Usage:"
            echo "  bmad-method install     # Install BMad in current project directory"
            echo "  (After install, you get access to agents and workflows)"
            echo ""
            echo "Note: BMad Method is an installer that sets up AI agents in your project"
            echo ""
          '';
        };
      };
    }
  );
}
