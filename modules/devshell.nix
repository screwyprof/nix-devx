{ inputs, ... }:
{
  imports = [
    inputs.git-hooks.flakeModule
  ];

  perSystem =
    { config, pkgs, ... }:
    {
      # Enable Nix language for this repository
      languages.nix.enable = true;

      # Enable recommended git hooks for Nix
      languages.nix.hooks = true;

      # Configure nix-filter for this project
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
          "repos"
        ];
      };

      # Default development shell for this repo
      devShells.default = pkgs.mkShellNoCC {
        inputsFrom = [
          config.devShells.nix
        ];

        shellHook = ''
          echo "🦊 Gopher's Environment Hub"
          echo "=========================="
          echo "Development shell for this repository"
          echo ""
          echo "Available devShells:"
          echo "  nix develop .#default    - This shell (Nix tooling)"
          echo "  nix develop .#nix        - Nix development"
          echo ""
        '';
      };
    };
}
