{
  description = "Gopher's Environment Hub";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-filter = {
      url = "github:numtide/nix-filter";
    };

    import-tree.url = "github:vic/import-tree";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [ inputs.import-tree ./modules ];

        flake.flakeModules = {
          ai-claude = import ./modules/ai/claude.nix;
          ai-bmad-method = import ./modules/ai/bmad-method.nix;
          languages-nix = import ./modules/languages/nix.nix;
          languages-go = import ./modules/languages/go.nix;
          languages-rust = import ./modules/languages/rust.nix;
        };

        perSystem =
          { config, pkgs, ... }:
          {
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
