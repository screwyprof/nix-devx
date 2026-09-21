{
  description = "Claude Code development shell (unrestricted)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-devx = {
      url = "path:../..";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nix-devx,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          nix-devx.flakeModules.ai-claude
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
            # Claude Code requires unfree package
            _module.args.pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            ai.claude = {
              enable = true;
              dangerouslySkipPermissions = true;
            };

            # Enable MCP servers
            mcp-servers = {
              programs = {
                # memory and sequential-thinking come from nixpkgs, not mcp-servers-nix: the latter
                # compiles the modelcontextprotocol/servers monorepo unpatched, which stopped
                # building once nixpkgs' `typescript` became 7.x (tsgo defaults `types` to `[]`, so
                # `@types/node` never loads). nixpkgs patches it, and its build is newer and cached.
                memory = {
                  enable = true;
                  package = pkgs.mcp-server-memory;
                };
                sequential-thinking = {
                  enable = true;
                  package = pkgs.mcp-server-sequential-thinking;
                };
              };
              flavors.claude-code.enable = true;
            };

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.ai.claude.devShellUnrestricted
                config.mcp-servers.devShell
              ];

              shellHook = ''
                echo "Claude Code Development Shell (unrestricted)"
                echo "============================================="
                echo ""
                echo "MCP Servers: memory, sequential-thinking"
                echo ""
                echo "Commands:"
                echo "  claude             - Start Claude Code"
                echo ""
              '';
            };
          };
      }
    );
}
