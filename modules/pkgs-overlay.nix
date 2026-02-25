{ inputs, config, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (_: prev: {
            ai = prev.callPackage ./pkgs/ai { };
          })
        ];
      };
    };
}
