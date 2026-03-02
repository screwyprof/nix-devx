{
  pkgs ? import <nixpkgs> { },
  self ? builtins.getFlake (toString ./..),
}:
let
  inherit (pkgs) lib;

  # Auto-discover shell directories
  shellsDir = ../shells;
  dirContents = builtins.readDir shellsDir;
  shellNames = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") dirContents);

  # Create a test derivation for each shell
  # This verifies the shell directory exists and has expected files
  mkShellTest =
    name:
    let
      shellPath = shellsDir + "/${name}";
    in
    pkgs.runCommand "check-shell-${name}" { } ''
      echo "Checking shell: ${name}"
      echo "Shell path: ${toString shellPath}"

      # Verify shell directory exists
      if [ ! -d "${shellPath}" ]; then
        echo "ERROR: Shell directory does not exist"
        exit 1
      fi

      # Verify flake.nix exists
      if [ ! -f "${shellPath}/flake.nix" ]; then
        echo "ERROR: Shell missing flake.nix"
        exit 1
      fi

      echo "Shell ${name} passed basic checks"
      touch $out
    '';
in
builtins.listToAttrs (map (name: lib.nameValuePair "shell-${name}" (mkShellTest name)) shellNames)
