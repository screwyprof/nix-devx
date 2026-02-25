{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.languages.nix;
    in
    {
      options.languages.nix = {
        enable = mkEnableOption "Nix language tooling";
      };

      config = mkIf cfg.enable {
        packages = {
          inherit (pkgs) nixfmt statix deadnix;
        };

        formatter = pkgs.nixfmt-tree;

        # Configure hooks for nix flake check (NOT for git installation)
        pre-commit.settings.hooks = {
          nixfmt.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          nil.enable = true;
          flake-checker.enable = true;
        };
      };
    }
  );
}
