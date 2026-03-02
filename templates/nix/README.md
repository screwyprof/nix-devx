# Nix Template

Nix development environment with nix-devx modules.

## Usage

```bash
nix flake init -t github:screwyprof/nix-devx#nix
```

## What's Included

- Nix tooling (nixfmt, statix, deadnix)
- Pre-commit hooks for Nix (nixfmt, statix, deadnix, nil, flake-checker)
- Formatter configuration

## After Init

1. Run `direnv allow` or `nix develop`
2. Start writing Nix!
