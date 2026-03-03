{
  pkgs ? import <nixpkgs> { },
  self ? builtins.getFlake (toString ./..),
}:
let
  inherit (pkgs) lib;

  # Get all template names from the flake
  templateNames = builtins.attrNames self.templates;

  # Check that a template flake.nix is structurally valid
  # - Can be imported as a Nix expression
  # - Has required attributes (description, inputs, outputs)
  # - outputs is a function
  mkTemplateTest =
    name: template:
    let
      templatePath = toString template.path;
      flakeFile = templatePath + "/flake.nix";

      # Import the flake.nix as a Nix expression
      flakeExpr = import flakeFile;

      # Check required attributes
      hasDescription = flakeExpr ? description;
      hasInputs = flakeExpr ? inputs;
      hasOutputs = flakeExpr ? outputs;
      outputsIsFunction = builtins.isFunction flakeExpr.outputs || (flakeExpr.outputs ? __functor);

      errors =
        lib.optional (!hasDescription) "missing description"
        ++ lib.optional (!hasInputs) "missing inputs"
        ++ lib.optional (!hasOutputs) "missing outputs"
        ++ lib.optional (!outputsIsFunction) "outputs is not a function";

      passed = errors == [ ];
    in
    pkgs.runCommand "check-template-${name}" { } ''
      echo "Checking template: ${name}"
      echo "Template path: ${templatePath}"

      # Verify template directory exists
      if [ ! -d "${templatePath}" ]; then
        echo "ERROR: Template directory does not exist"
        exit 1
      fi

      # Verify flake.nix exists
      if [ ! -f "${flakeFile}" ]; then
        echo "ERROR: Template missing flake.nix"
        exit 1
      fi

      # Verify README.md exists (documentation requirement)
      if [ ! -f "${templatePath}/README.md" ]; then
        echo "ERROR: Template missing README.md"
        exit 1
      fi

      ${lib.optionalString (!passed) ''
        echo "ERROR: Template structure validation failed:"
        ${lib.concatMapStrings (e: ''echo "  - ${e}"'') errors}
        exit 1
      ''}

      echo "Template ${name} passed all checks"
      echo "  - Has description: ${toString hasDescription}"
      echo "  - Has inputs: ${toString hasInputs}"
      echo "  - Has outputs function: ${toString outputsIsFunction}"
      touch $out
    '';
in
builtins.listToAttrs (
  map (
    name: lib.nameValuePair "template-${name}" (mkTemplateTest name self.templates.${name})
  ) templateNames
)
