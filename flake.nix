{
  description = "Claude Code Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    #systems.url = "github:nix-systems/default";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, mcp-servers-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;
      imports = [ inputs.mcp-servers-nix.flakeModule ];

      perSystem = { config, pkgs, system, inputs', ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        packages.claude-wrapper = pkgs.writeShellApplication {
          name = "claude";
          runtimeInputs = [ pkgs.claude-code ];
          text = ''
            exec claude --dangerously-skip-permissions "$@"
          '';
        };

        mcp-servers = {
          programs = {
            context7.enable = true;
            memory.enable = true;
            sequential-thinking.enable = true;
            serena.enable = true;
          };
          flavors.claude-code.enable = true; # Generates .mcp.json config
        };

        devShells.default = pkgs.mkShellNoCC {
          #packages = with pkgs; [
            #claude-code
            #nodejs # claude's vscode extension for some reason need it
          #];

          buildInputs = [ pkgs.nodejs ] ++ config.mcp-servers.packages;

          shellHook = config.mcp-servers.shellHook +
            ''
              set -euo pipefail

              # Project root & stable hash
              PROJECT_ROOT="''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
              PROJECT_HASH="''${PROJECT_HASH:-$(printf '%s\\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}"

              export CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/claude/$PROJECT_HASH}"
              mkdir -p "$CLAUDE_CONFIG_DIR"

              echo 🔧 Claude Dev Shell Ready
              echo • Claude version: $(claude -v 2>/dev/null || echo "unknown")
              echo • PROJECT_ROOT: $PROJECT_ROOT
              echo • CLAUDE_CONFIG_DIR: $CLAUDE_CONFIG_DIR

              if [ -z "''${ANTHROPIC_AUTH_TOKEN:-}" ]; then
                echo ⚠️ Warning: ANTHROPIC_AUTH_TOKEN is not set
              fi

              # Add wrapper to PATH so it overrides claude-code
              export PATH="${config.packages.claude-wrapper}/bin:$PATH"

              # Suggest init if needed
              if [ ! -d .claude ]; then
                echo "💡 No .claude directory found. You can initialize project settings by running 'claude /init'."
              fi
            '';
        };
      };
    });
}
