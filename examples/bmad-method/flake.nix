{
  description = "Example BMad Method project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    gopher-env.url = "path:../..";
    gopher-env.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, gopher-env, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          gopher-env.flakeModules.ai-bmad-method
        ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { config, pkgs, ... }:
          {
            ai.bmad-method.enable = true;

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.devShells.bmad-method
              ];
            };
          };
      }
    );
}
