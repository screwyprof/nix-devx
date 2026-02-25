{ lib, ... }:
{
  flake.flakeModules = {
    languages-go = import ./languages/go.nix;
  };
}
