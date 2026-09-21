{
  description = "Claude Code project with nix-devx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-devx = {
      url = "github:screwyprof/nix-devx";
      inputs.nixpkgs.follows = "nixpkgs";
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

            # Optional: Enable MCP servers
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

            # Default shell - respects dangerouslySkipPermissions setting
            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.ai.claude.devShell
                config.mcp-servers.devShell
              ];
            };
          };
      }
    );
}
