# The language → VS Code extension table. A PURE function of pkgs, deliberately not a flake-parts
# module, because it has two consumers that cannot share one:
#
#   modules/editors/vscode.nix  — the adapter, INSIDE a shell eval, gated on `languages.<x>.enable`
#   modules/flake-modules.nix   — `flake.lib.vscodeExtensionsFor`, for consumers with no shell eval
#                                 at all (a home-manager config picking extensions for a laptop)
#
# One definition, two faces. Duplicating it would mean the pairing drifts, which is the whole reason
# these lists live beside the toolchains rather than in someone's personal config.
pkgs:
let
  e = pkgs.vscode-extensions;
  # Not in nixpkgs. A pin fixes exactly which bytes run and fails closed if the artifact changes.
  m = pkgs.vscode-utils.extensionFromVscodeMarketplace;
in
{
  go = [
    e.golang.go
    (m {
      publisher = "ryanluker";
      name = "vscode-coverage-gutters";
      version = "2.14.0";
      sha256 = "sha256-waF3FmncUsXqWFWGRy9X7RQ29BDRYlaqyFhEXg4HXNo=";
    })
    (m {
      publisher = "premparihar";
      name = "gotestexplorer";
      version = "0.1.13";
      sha256 = "sha256-CIqZ1yE9bAHuKvVcdD+Ph8kPgo/a9N+zqELYWxVV8F8=";
    })
  ];

  rust = [
    e.rust-lang.rust-analyzer # a THIN CLIENT: the analyzer binary comes from the devShell
    e.tamasfe.even-better-toml
    e.vadimcn.vscode-lldb
    e.fill-labs.dependi # UNFREE
  ];

  nix = [
    e.jnoortheen.nix-ide
  ];
}
