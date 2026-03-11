{
  description = "Nix project with nix-devx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-filter.url = "github:numtide/nix-filter";
    nix-devx = {
      url = "github:screwyprof/nix-devx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
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
                config.languages.nix.devShell
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
