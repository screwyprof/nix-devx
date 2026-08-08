{ lib, self, ... }:
{
  flake.flakeModules = {
    languages-go = import ./languages/go.nix;
    languages-rust = import ./languages/rust.nix;
    languages-nix = import ./languages/nix.nix;
    ai-bmad-method = import ./ai/bmad-method.nix;
    ai-claude = import ./ai/claude.nix;
    # Editor ADAPTERS: one per editor, mapping this repo's language facts onto that editor's packaging.
    # Kept out of the language modules so adding Helix/Emacs/Zed is one new file, not an option in every
    # language module (N + M, not N x M).
    editors-vscode = import ./editors/vscode.nix;
  };

  # The same language -> extension table the vscode adapter uses, exposed for consumers that have no
  # shell eval to hang it off — a home-manager config choosing extensions for a laptop, or a devbox
  # session flake composing a per-project set. Takes pkgs, returns { go, rust, nix } lists.
  #
  #   inputs.nix-devx.lib.vscodeExtensionsFor pkgs  ->  { go = [...]; rust = [...]; nix = [...]; }
  flake.lib.vscodeExtensionsFor = pkgs: import ./editors/_vscode-sets.nix pkgs;

  # The same extensions, PACKAGED as a directory a consumer can place verbatim — the extension dirs plus
  # the `extensions.json` the server needs.
  #
  #   inputs.nix-devx.lib.vscodeServerExtensions { inherit pkgs; exts = [ … ]; }
  #     -> a derivation; place "${it}/share/vscode/extensions"
  #
  # WHY PACKAGED HERE rather than by each consumer. Every devbox session flake currently hand-wraps the
  # list in its own `buildEnv`, identically, and every one of them omits the manifest — because a bare
  # `buildEnv` of extensions has no reason to know about it. That omission is not cosmetic: a read-only
  # extensions dir WITHOUT `extensions.json` fails outright ("Unable to read file … extensions.json"),
  # where one WITH it serves fine. Measured against code-server 1.129.1, including a real workbench
  # connect. Knowing that is editor knowledge, so it belongs in this repo and not in the consumer's.
  #
  # The manifest is GENERATED, never hand-written, and it is what makes a REMOVAL take effect: the server
  # rebuilds its index only when the file is ABSENT, so a stale one leaves a dropped extension listed as
  # `isValid: false`, warning on every connect. Replacing the manifest together with the directory means
  # that state cannot arise.
  flake.lib.vscodeServerExtensions =
    { pkgs, exts }:
    pkgs.buildEnv {
      name = "vscode-server-extensions";
      paths = exts ++ [
        (pkgs.writeTextFile {
          name = "vscode-server-extensions-json";
          text = pkgs.vscode-utils.toExtensionJson exts;
          destination = "/share/vscode/extensions/extensions.json";
        })
      ];
    };

  flake.templates = {
    minimal = {
      path = ./../templates/minimal;
      description = "Minimal flake-parts setup with basic devShell";
    };

    go = {
      path = ./../templates/go;
      description = "Go development environment with linting and hooks";
    };

    rust = {
      path = ./../templates/rust;
      description = "Rust development environment with cargo extensions";
    };

    nix = {
      path = ./../templates/nix;
      description = "Nix development environment with formatting and linting";
    };

    goenv = {
      path = ./../templates/goenv;
      description = "Go + Claude Code + Nix devcontainer with MCP servers, coverage, and debugging";
    };

    claude = {
      path = ./../templates/claude;
      description = "Claude Code environment with MCP servers";
    };

    claude-unrestricted = {
      path = ./../shells/claude-unrestricted;
      description = "Claude Code environment with MCP servers (unrestricted)";
    };

    default = self.templates.minimal;
  };
}
