{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    concatLists
    mkOption
    optionals
    types
    ;
in
{
  # VS Code ADAPTER: maps this repo's language facts onto VS Code packaging.
  #
  # An adapter rather than a `languages.<x>.vscodeExtensions` option, because a language module knows
  # FACTS — Go's LSP is gopls — and `golang.go` is VS Code's PACKAGING of one. Editor lists inside
  # language modules would make every language module carry every editor's schema (marketplace
  # extensions here, a languages.toml stanza for Helix, packages for Emacs): N x M files, and language
  # authors learning editor formats they do not care about.
  #
  # Adapters make it N + M — a new editor is ONE file. The N x M facts are irreducible (`gopls ->
  # golang.go` is not computable) but they live per-editor. Note the asymmetry for whoever writes the
  # next one: Helix/Emacs/vim need the LSP BINARY plus a small stanza, and the binary is already in the
  # devShell, so those adapters are largely derivable. Only marketplace editors (VS Code, Zed) need a
  # hand-maintained table like ./_vscode-sets.nix.
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      ...
    }:
    let
      # A consuming shell imports only the language modules it wants, so `languages.rust` may not exist
      # at all. `or false` guards the whole attrpath — no `options ?` probing, and it reads as the
      # question being asked: is this language enabled, if it is even present?
      enabled = name: config.languages.${name}.enable or false;
      sets = import ./_vscode-sets.nix pkgs;
    in
    {
      options.editors.vscode = {
        extensions = mkOption {
          type = types.listOf types.package;
          readOnly = true;
          description = ''
            VS Code extensions implied by the languages enabled in this shell.

            READ-ONLY and inert: enabling a language yields a toolchain, never an installed extension.
            A consumer opts in explicitly (a devbox session flake composes this into its declared set),
            so a headless shell that wants only the toolchain carries no extension closure — and none
            of the unfree ones reach anyone who did not ask for an editor.
          '';
        };
      };

      config.editors.vscode.extensions = concatLists (
        map (name: optionals (enabled name) sets.${name}) (builtins.attrNames sets)
      );
    }
  );
}
