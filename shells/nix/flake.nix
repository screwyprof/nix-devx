{
  description = "Nix development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-devx = {
      url = "path:../..";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{ flake-parts, nix-devx, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [ nix-devx.flakeModules.languages-nix ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { config, pkgs, ... }:
          {
            languages.nix.enable = true;

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [ config.languages.nix.devShell ];

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
