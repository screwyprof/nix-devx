{ inputs, ... }:
{
  perSystem =
    { ... }:
    {
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
    };
}
