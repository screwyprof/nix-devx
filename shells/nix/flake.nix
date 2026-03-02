{
  description = "Nix development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    nix-devx.url = "github:screwyprof/nix-devx";
    nix-devx.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, nix-devx, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          inputs.git-hooks.flakeModule
          nix-devx.flakeModules.languages-nix
        ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { config, pkgs, ... }:
          {
            languages.nix.enable = true;

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [ config.devShells.nix ];

              shellHook = ''
                echo "Nix Development Shell"
                echo "====================="
                echo ""
                echo "Tools: nixfmt, statix, deadnix"
                echo ""
                echo "Commands:"
                echo "  nixfmt *.nix       - Format Nix files"
                echo "  statix check .     - Static analysis"
                echo "  deadnix .          - Find dead code"
                echo ""
              '';
            };
          };
      }
    );
}
