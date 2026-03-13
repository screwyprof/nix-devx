{
  buildGoModule,
  nix-filter,
}:
buildGoModule {
  pname = "hello";
  version = "0.1.0";
  src = nix-filter.filter {
    root = ./.;
    include = [
      (nix-filter.matchExt "go")
      (nix-filter.matchExt "mod")
      (nix-filter.matchExt "sum")
    ];
  };
  vendorHash = null;
  meta.mainProgram = "hello";
}
