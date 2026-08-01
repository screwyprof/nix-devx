{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    concatMap
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
            VS Code extensions implied by the languages enabled in this shell, plus the
            editor core (direnv) that makes any of them functional.

            READ-ONLY and inert: enabling a language yields a toolchain, never an installed extension.
            A consumer opts in explicitly (a devbox session flake composes this into its declared set),
            so a headless shell that wants only the toolchain carries no extension closure — and none
            of the unfree ones reach anyone who did not ask for an editor.
          '';
        };
      };

      # The RAIL, not taste. mkhl.direnv calls `updateProcessEnv`, mutating the extension host's own
      # environment, so every language extension below inherits the devShell this flake defines. Without
      # it they are thin clients with nothing behind them: measured 2026-08-01, a language-only set left
      # rust-analyzer reporting `cargo: No such file or directory` in a project whose shell provides cargo.
      # It lives here rather than in the language table because it pairs with the SHELL, not with any one
      # language — and here it is paid for only by consumers that asked for an editor.
      config.editors.vscode.extensions = [
        pkgs.vscode-extensions.mkhl.direnv
      ]
      # Pairs with the TOOL, exactly as rust-analyzer pairs with the rust toolchain: a shell that
      # enables ai.claude gets the editor half; one that does not has it ABSENT, not disabled.
      ++ optionals (config.ai.claude.enable or false) [ pkgs.vscode-extensions.anthropic.claude-code ]
      ++ concatMap (name: optionals (enabled name) sets.${name}) (builtins.attrNames sets);
    }
  );
}
