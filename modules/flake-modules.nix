{ lib, ... }:
{
  flake.flakeModules = {
    languages-go = import ./languages/go.nix;
    languages-rust = import ./languages/rust.nix;
    languages-nix = import ./languages/nix.nix;
    ai-bmad-method = import ./ai/bmad-method.nix;
    ai-claude = import ./ai/claude.nix;
  };
}
