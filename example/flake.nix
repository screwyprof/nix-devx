{
  description = "Example project using Go flake module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Import the Go module from the parent flake
    repo.url = "path:+..";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem =
        { config, pkgs, ... }:
        {
          # Import the Go language module
          imports = [
            inputs.repo.flakeModules.languages-go
          ];

          # Enable Go for this project
          languages.go.enable = true;

          # Default development shell
          devShells.default = pkgs.mkShell {
            inputsFrom = [ config.devShells.go ];
          };
        };
    };
}
