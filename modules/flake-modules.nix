{ lib, ... }:
{
  flake.flakeModules = {
    languages-go = import ./languages/go.nix;
    languages-rust = import ./languages/rust.nix;
    languages-nix = import ./languages/nix.nix;
    ai-bmad-method = import ./ai/bmad-method.nix;
    ai-claude = import ./ai/claude.nix;
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

    claude = {
      path = ./../templates/claude;
      description = "Claude Code environment with MCP servers";
    };
  };
}
