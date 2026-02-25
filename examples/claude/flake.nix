{
  description = "Example Claude Code project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gopher-env = {
      url = "path:../..";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      gopher-env,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          gopher-env.flakeModules.ai-claude
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
            _module.args.pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            ai.claude = {
              enable = true;
              dangerouslySkipPermissions = true;
              baseUrl = "https://api.z.ai";
              models = {
                default = "glm-5";
                opus = "glm-4.7";
                sonnet = "glm-4.7";
                haiku = "glm-4.5-air";
              };
            };

            mcp-servers = {
              programs = {
                memory.enable = true;
                sequential-thinking.enable = true;
              };
              flavors.claude-code.enable = true;
            };

            devShells.default = pkgs.mkShellNoCC {
              inputsFrom = [
                config.devShells.claude
              ];
            };
          };
      }
    );
}
