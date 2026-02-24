{
  description = "Claude Code Flake Module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    flakeModule = { ... }: {
      imports = [
        inputs.mcp-servers-nix.flakeModule
        ./claude-flake-module.nix
      ];
    };
  };
}
