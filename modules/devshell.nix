{ inputs, ... }:
{
  imports = [
    inputs.git-hooks.flakeModule
    inputs.mcp-servers-nix.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
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

      # Allow unfree packages (needed for claude-code)
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Configure Claude Code
      ai.claude.enable = true;

      # Configure MCP servers
      mcp-servers = {
        programs = {
          memory.enable = true;
          sequential-thinking.enable = true;
        };
        flavors.claude-code.enable = true;
      };

      # Default development shell for this repo
      devShells.default = pkgs.mkShellNoCC {
        inputsFrom = [
          config.devShells.nix
          config.devShells.claude
        ];

        shellHook = ''
          rm -r .pre-commit-config.yaml
          ${config.pre-commit.shellHook}
          echo "🦊 Gopher's Environment Hub"
          echo "=========================="
          echo "Development shell for this repository"
          echo ""
          echo "Available devShells:"
          echo "  nix develop .#default    - This shell (Nix + Claude tooling)"
          echo "  nix develop .#nix        - Nix development only"
          echo "  nix develop .#claude     - Claude Code only"
          echo ""
        '';
      };
    };
}
