{
  description = "Example Go project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    nix-filter.url = "github:numtide/nix-filter";

    gopher-env.url = "path:../..";
    gopher-env.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, gopher-env, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          inputs.git-hooks.flakeModule
          gopher-env.flakeModules.languages-go
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
                config.devShells.go
              ];

              shellHook = ''
                echo "🔷 Go Example Project"
                echo "====================="
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
