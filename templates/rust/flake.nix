{
  description = "Rust project with nix-devx";

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
          nix-devx.flakeModules.languages-rust
        ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { config, pkgs, ... }:
          {
            languages.rust.enable = true;
            languages.rust.hooks = true;

            pre-commit.settings.src = inputs.nix-filter.lib.filter {
              root = ./.;
              include = [
                (inputs.nix-filter.lib.matchExt "rs")
                (inputs.nix-filter.lib.matchExt "toml")
                "flake.lock"
              ];
              exclude = [
                ".direnv"
                ".git"
                "result"
                "target"
              ];
            };

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.devShells.rust
              ];

              shellHook = ''
                echo "Rust Project"
                echo "============"
                echo ""
                echo "Available commands:"
                echo "  cargo run          - Run the project"
                echo "  cargo test         - Run tests"
                echo "  cargo clippy       - Run linter"
                echo "  cargo fmt          - Format code"
                echo ""
              '';
            };
          };
      }
    );
}
