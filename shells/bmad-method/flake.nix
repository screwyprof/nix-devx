{
  description = "BMad Method development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-devx.url = "github:screwyprof/nix-devx";
    nix-devx.inputs.nixpkgs.follows = "nixpkgs";
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
              inputsFrom = [ config.devShells.bmad-method ];
            };
          };
      }
    );
}
