{
  inputs,
  config,
  lib,
  self,
  ...
}:
{
  imports = [
    # nix-devx modules (imported by path)
    ../modules/languages/nix.nix
    ../modules/ai/claude.nix

    # Dev-only external modules
    inputs.git-hooks.flakeModule
    inputs.mcp-servers-nix.flakeModule
  ];

  systems = lib.systems.flakeExposed;

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
        root = ./..;
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

      # Default development shell for this repo (host)
      devShells.default = pkgs.mkShellNoCC {
        inputsFrom = [
          config.languages.nix.devShell
          config.ai.claude.devShell
          config.mcp-servers.devShell
          config.pre-commit.devShell
        ];

        nativeBuildInputs = [
          (pkgs.bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
          ]))
          pkgs.delta
          pkgs.shellcheck
        ];

        shellHook = ''
          echo "nix-devx"
          echo "========"
          echo "Modular development environments with flake-parts"
          echo ""
          echo "Available devShells:"
          echo "  nix develop .#default    - This shell (Nix + Claude tooling)"
          echo "  nix develop .#container  - Container shell (unrestricted Claude)"
          echo ""
        '';
      };

      # Container development shell (unrestricted Claude for trusted environments)
      devShells.container = pkgs.mkShellNoCC {
        inputsFrom = [
          config.languages.nix.devShell
          config.ai.claude.devShellUnrestricted
          config.mcp-servers.devShell
          config.pre-commit.devShell
        ];

        nativeBuildInputs = [
          (pkgs.bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
          ]))
          pkgs.delta
          pkgs.shellcheck
        ];

        shellHook = ''
          echo "nix-devx (container)"
          echo "===================="
          echo "Modular development environments with flake-parts"
          echo ""
          echo "Running in unrestricted mode (trusted container environment)"
          echo ""
        '';
      };
    };

  flake.config.config = config;
  flake.options.mySystem = lib.mkOption { default = config.allSystems.${builtins.currentSystem}; };
}
