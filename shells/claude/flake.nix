{
  description = "Claude Code development shell";

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
              dangerouslySkipPermissions = false;
            };

            # Enable MCP servers
            mcp-servers = {
              programs = {
                memory.enable = true;
                sequential-thinking.enable = true;
              };
              flavors.claude-code.enable = true;
            };

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.ai.claude.devShell
                config.mcp-servers.devShell
              ];

              shellHook = ''
                echo "Claude Code Development Shell"
                echo "============================="
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
