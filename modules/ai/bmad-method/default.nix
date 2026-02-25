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
      cfg = config.ai.bmad-method;
    in
    {
      options.ai.bmad-method = {
        enable = mkEnableOption "BMad Method AI framework";

        nodejs = mkOption {
          type = types.package;
          default = pkgs.nodejs_20;
          description = "Node.js package to use";
        };
      };

      config = mkIf cfg.enable {
        packages.bmad-method =
          if cfg.package != null then
            cfg.package
          else
            pkgs.buildNpmPackage {
              pname = "bmad-method";
              version = "6.0.0-alpha.12";

              inherit (cfg) nodejs;

              src = pkgs.fetchFromGitHub {
                owner = "bmad-code-org";
                repo = "BMAD-METHOD";
                rev = "9d510fc0751889a521f50fc3575393b09bd90e9b";
                hash = "sha256-QYH6M7qz++CuXYBeh4LWSlB1JByuinhuG3PwwAkt6Zs=";
              };

              npmDepsHash = "sha256-AJaVkMAkNmfGFqOoBjXbWLMJc14KjdWhIsB1RFYKQug=";

              dontNpmBuild = true;
              npmPrune = false;

              nativeBuildInputs = [ pkgs.makeWrapper ];

              postInstall = ''
                wrapProgram $out/bin/bmad-method \
                  --set NODE_PATH "$out/lib/node_modules/bmad-method" \
                  --prefix PATH : ${pkgs.lib.makeBinPath [ cfg.nodejs ]}

                if [ -f "$out/bin/bmad" ]; then
                  wrapProgram $out/bin/bmad \
                    --set NODE_PATH "$out/lib/node_modules/bmad-method" \
                    --prefix PATH : ${pkgs.lib.makeBinPath [ cfg.nodejs ]}
                fi
              '';

              meta = {
                description = "Universal AI Agent Framework for AI-assisted development";
                homepage = "https://github.com/bmadcode/BMAD-METHOD";
                license = pkgs.lib.licenses.mit;
                mainProgram = "bmad-method";
                platforms = pkgs.lib.platforms.all;
              };
            };

        devShells.bmad-method = pkgs.mkShell {
          buildInputs = [
            config.packages.bmad-method
            cfg.nodejs
          ];

          shellHook = ''
            echo "🤖 BMad Method Development Environment"
            echo "======================================"
            bmad-method --version || echo "BMad Method not yet available"
            node --version
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
