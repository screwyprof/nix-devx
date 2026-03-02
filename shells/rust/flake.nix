{
  description = "Rust development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
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

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [ config.devShells.rust ];

              shellHook = ''
                echo "Rust Development Shell"
                echo "======================"
                echo ""
                echo "Tools: rustc, cargo, bacon, cargo-edit, cargo-audit, cargo-nextest, cargo-watch"
                echo ""
                echo "Commands:"
                echo "  cargo build        - Build the project"
                echo "  cargo test         - Run tests"
                echo "  bacon              - Continuous test runner"
                echo "  cargo watch -x run - Auto-rebuild on changes"
                echo ""
              '';
            };
          };
      }
    );
}
