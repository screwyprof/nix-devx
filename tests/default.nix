{
  pkgs ? import <nixpkgs> { },
  self ? builtins.getFlake (toString ./..),
}:
let
  inherit (pkgs) lib;
in
lib.mergeAttrsList [
  (import ./templates.nix { inherit pkgs self; })
  (import ./shells.nix { inherit pkgs self; })
]
