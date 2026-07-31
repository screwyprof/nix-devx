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
