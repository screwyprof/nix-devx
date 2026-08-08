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
      cfg = config.editors.vscode;
    in
    {
      options.editors.vscode = {
        direnv.enable = mkOption {
          type = types.bool;
          # Off fails silently: language extensions with no devShell behind them, which surfaces as
          # "cargo: No such file or directory". On is at worst one inert extension.
          default = true;
          description = ''
            Include `mkhl.direnv`, which loads this devShell into the extension host.
            Turn off when the shell reaches the editor another way.
          '';
        };

        errorlens.enable = mkOption {
          type = types.bool;
          # PRESENTATIONAL, unlike direnv above — nothing fails without it. On by default because every
          # language module here supplies an LSP, and this is what makes those diagnostics visible
          # without hovering each one; a shell that enables a language and then cannot see its errors
          # inline is the surprising default, not the other way round.
          default = true;
          description = ''
            Include `usernamehw.errorlens`, which renders diagnostics inline beside the code.
            Turn off to keep diagnostics in the Problems panel only.
          '';
        };

        extensions = mkOption {
          type = types.listOf types.package;
          readOnly = true;
          description = ''
            VS Code extensions implied by the languages enabled in this shell, plus the
            editor-core ones (direnv, errorlens).

            READ-ONLY and inert: enabling a language yields a toolchain, never an installed extension.
            A consumer opts in explicitly (a devbox session flake composes this into its declared set),
            so a headless shell that wants only the toolchain carries no extension closure — and none
            of the unfree ones reach anyone who did not ask for an editor.
          '';
        };

        extensionsDir = mkOption {
          type = types.package;
          readOnly = true;
          description = ''
            The same set, PACKAGED as a directory a consumer places verbatim — the extension
            directories plus the `extensions.json` the server needs. Place
            `''${extensionsDir}/share/vscode/extensions`.

            Prefer this over composing `extensions` by hand. A bare `buildEnv` of the list omits the
            manifest, and a read-only extensions dir without one fails outright rather than degrading —
            which is why every consumer that hand-wrapped the list produced a broken directory.

            Still inert: building the option costs nothing until something places it.
          '';
        };
      };

      # mkhl.direnv loads the devShell into the extension host; without it the language
      # extensions below have no binaries.
      config.editors.vscode.extensions =
        optionals cfg.direnv.enable [ pkgs.vscode-extensions.mkhl.direnv ]
        ++ optionals cfg.errorlens.enable [ pkgs.vscode-extensions.usernamehw.errorlens ]
        ++ optionals (config.ai.claude.enable or false) [ pkgs.vscode-extensions.anthropic.claude-code ]
        ++ concatMap (name: optionals (enabled name) sets.${name}) (builtins.attrNames sets);

      # The packaged form, composed from the list above so the two cannot drift. Inlined rather than
      # calling `flake.lib.vscodeServerExtensions`: inside `mkPerSystemOption`, `config` is the PER-SYSTEM
      # config and has no `flake` attribute, so reaching the lib from here is not available.
      config.editors.vscode.extensionsDir = pkgs.buildEnv {
        name = "vscode-server-extensions";
        paths = cfg.extensions ++ [
          (pkgs.writeTextFile {
            name = "vscode-server-extensions-json";
            text = pkgs.vscode-utils.toExtensionJson cfg.extensions;
            destination = "/share/vscode/extensions/extensions.json";
          })
        ];
      };
    }
  );
}
