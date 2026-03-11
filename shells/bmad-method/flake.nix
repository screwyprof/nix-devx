{
  description = "BMad Method development shell";

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
        imports = [ nix-devx.flakeModules.ai-bmad-method ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { config, pkgs, ... }:
          {
            ai.bmad-method.enable = true;

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [ config.ai.bmad-method.devShell ];
            };
          };
      }
    );
}
