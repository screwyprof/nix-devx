{
  pkgs ? import <nixpkgs> { },
  self ? builtins.getFlake (toString ./..),
}:
let
  inherit (pkgs) lib;

  # Get all template names from the flake
  templateNames = builtins.attrNames self.templates;

  # Create a test derivation for each template
  # This verifies the template path exists and contains expected files
  mkTemplateTest =
    name: template:
    pkgs.runCommand "check-template-${name}" { } ''
      echo "Checking template: ${name}"
      echo "Template path: ${toString template.path}"

      # Verify template directory exists
      if [ ! -d "${template.path}" ]; then
        echo "ERROR: Template directory does not exist"
        exit 1
      fi

      # Verify flake.nix exists
      if [ ! -f "${template.path}/flake.nix" ]; then
        echo "ERROR: Template missing flake.nix"
        exit 1
      fi

      # Verify README.md exists (documentation requirement)
      if [ ! -f "${template.path}/README.md" ]; then
        echo "ERROR: Template missing README.md"
        exit 1
      fi

      echo "Template ${name} passed basic checks"
      touch $out
    '';
in
builtins.listToAttrs (
  map (
    name: lib.nameValuePair "template-${name}" (mkTemplateTest name self.templates.${name})
  ) templateNames
)
