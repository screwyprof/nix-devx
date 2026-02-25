{ inputs, ... }:
{
  imports = [
    inputs.mcp-servers-nix.flakeModule
  ];
}
