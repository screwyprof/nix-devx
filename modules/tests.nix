{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = import ../tests {
        inherit pkgs self;
      };
    };
}
