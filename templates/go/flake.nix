{
  description = "Go project with nix-devx";

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
          nix-devx.flakeModules.languages-go
        ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { config, pkgs, ... }:
          {
            languages.go.enable = true;
            languages.go.hooks = true;

            pre-commit.settings.src = inputs.nix-filter.lib.filter {
              root = ./.;
              include = [
                (inputs.nix-filter.lib.matchExt "go")
                (inputs.nix-filter.lib.matchExt "mod")
                (inputs.nix-filter.lib.matchExt "sum")
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
                config.languages.go.devShell
              ];

              shellHook = ''
                echo "Go Project"
                echo "=========="
                echo ""
                echo "Available commands:"
                echo "  go run .           - Run the project"
                echo "  go test ./...      - Run tests"
                echo "  gofumpt -l .       - Check formatting"
                echo "  golangci-lint run  - Run linter"
                echo ""
              '';
            };
          };
      }
    );
}
