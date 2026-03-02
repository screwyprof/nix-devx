{
  description = "Nix project with nix-devx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    nix-filter.url = "github:numtide/nix-filter";

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
            languages.nix.hooks = true;

            pre-commit.settings.src = inputs.nix-filter.lib.filter {
              root = ./.;
              include = [
                (inputs.nix-filter.lib.matchExt "nix")
                "flake.lock"
              ];
              exclude = [
                ".direnv"
                ".git"
                "result"
              ];
            };

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.devShells.nix
              ];

              shellHook = ''
                echo "Nix Project"
                echo "==========="
                echo ""
                echo "Available commands:"
                echo "  nix fmt            - Format Nix files"
                echo "  nix flake check    - Run all checks (formatting, linting)"
                echo ""
              '';
            };
          };
      }
    );
}
