{
  description = "Minimal flake-parts project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = lib.systems.flakeExposed;

        perSystem =
          { pkgs, ... }:
          {
            devShells.default = pkgs.mkShellNoCC {
              shellHook = ''
                echo "Minimal development environment"
              '';
            };
          };
      }
    );
}
