{
  description = "Gopher's Environment Hub";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ensure you have the MCP servers input here so your module can find it
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-filter = {
      url = "github:numtide/nix-filter";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      git-hooks,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          git-hooks.flakeModule
          ./modules/ai/claude
          ./modules/languages/nix
          ./modules/languages/go
          ./modules/languages/rust
          inputs.mcp-servers-nix.flakeModule
        ];

        systems = lib.systems.flakeExposed;

        flake.flakeModules = {
          ai-claude = import ./modules/ai/claude;
          languages-nix = import ./modules/languages/nix;
          languages-go = import ./modules/languages/go;
          languages-rust = import ./modules/languages/rust;
        };

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

            languages.nix.enable = true;

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
              ];
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

            # Use Claude devShell and add git hooks + MCP servers for THIS repo
            devShells.default = pkgs.mkShell {
              inputsFrom = [ config.devShells.claude ];
              shellHook = ''
                ${config.pre-commit.shellHook}
                ${config.mcp-servers.shellHook}
              '';
            };
          };
      }
    );
}
