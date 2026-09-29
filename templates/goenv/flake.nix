{
  description = "Go project with nix-devx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-filter.url = "github:numtide/nix-filter";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-devx = {
      url = "github:screwyprof/nix-devx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          inputs.treefmt-nix.flakeModule
          inputs.git-hooks.flakeModule
          inputs.mcp-servers-nix.flakeModule
          inputs.nix-devx.flakeModules.ai-claude
          inputs.nix-devx.flakeModules.languages-nix
          inputs.nix-devx.flakeModules.languages-go
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
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            ai.claude.enable = true;

            # Optional: Enable MCP servers
            mcp-servers = {
              programs = {
                memory.enable = true;
                sequential-thinking.enable = true;
              };
              flavors.claude-code.enable = true;
            };

            languages = {
              nix = {
                enable = true;
                hooks = true;
                formatters = true;
              };

              go = {
                enable = true;
                hooks = true;
                formatters = true;
              };
            };

            pre-commit.settings.src = inputs.nix-filter.lib.filter {
              root = ./.;
              include = [
                (inputs.nix-filter.lib.matchExt "go")
                (inputs.nix-filter.lib.matchExt "mod")
                (inputs.nix-filter.lib.matchExt "sum")
                (inputs.nix-filter.lib.matchExt "nix")
                "flake.lock"
              ];
              exclude = [
                ".direnv"
                ".git"
                "result"
              ];
            };

            packages.default = pkgs.callPackage ./package.nix {
              nix-filter = inputs.nix-filter.lib;
            };

            devShells =
              let
                commonInputs = [
                  config.mcp-servers.devShell
                  config.languages.go.devShell
                  config.languages.nix.devShell
                ];
              in
              {
                # Host: respects dangerouslySkipPermissions (default: false)
                default = pkgs.mkShellNoCC {
                  inputsFrom = [ config.ai.claude.devShell ] ++ commonInputs;
                };

                # Container: always skips permissions
                container = pkgs.mkShellNoCC {
                  inputsFrom = [ config.ai.claude.devShellUnrestricted ] ++ commonInputs;
                };
              };
          };
      }
    );
}
