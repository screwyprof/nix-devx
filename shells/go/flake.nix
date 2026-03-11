{
  description = "Go development shell";

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
        imports = [ nix-devx.flakeModules.languages-go ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { config, pkgs, ... }:
          {
            languages.go.enable = true;

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [ config.languages.go.devShell ];

              shellHook = ''
                echo "Go Development Shell"
                echo "===================="
                echo ""
                echo "Tools: go, gopls, delve, golangci-lint, gofumpt, golines, gci"
                echo ""
                echo "Commands:"
                echo "  go version         - Check Go version"
                echo "  golangci-lint run  - Run linter"
                echo "  gofumpt -l .       - Check formatting"
                echo ""
              '';
            };
          };
      }
    );
}
