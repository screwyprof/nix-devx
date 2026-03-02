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
              # Set to true only in trusted environments (e.g., devcontainers)
              # Or use devShells.claude-unrestricted instead
              dangerouslySkipPermissions = false;
            };

            # Optional: Enable MCP servers
            mcp-servers = {
              programs = {
                memory.enable = true;
                sequential-thinking.enable = true;
              };
              flavors.claude-code.enable = true;
            };

            # Default shell - respects dangerouslySkipPermissions setting
            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.devShells.claude
              ];
            };

            # Unrestricted shell - always skips permissions
            # Use this for trusted environments like devcontainers
            # devShells.container = pkgs.mkShellNoCC {
            #   inputsFrom = [ config.devShells.claude-unrestricted ];
            # };
          };
      }
    );
}
