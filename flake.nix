{
  description = "nix-devx - Modular development environments with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          inputs.flake-parts.flakeModules.partitions
          (inputs.import-tree ./modules)
        ];

        systems = lib.systems.flakeExposed;

        # Map dev-specific attributes to the dev partition
        partitionedAttrs = {
          devShells = "dev";
          checks = "dev";
          formatter = "dev";
        };

        # Dev partition with extra inputs
        partitions.dev.extraInputsFlake = ./dev;
        partitions.dev.module = ./dev/flake-module.nix;
      }
    );
}
