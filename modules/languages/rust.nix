{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    optionals
    types
    ;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      options,
      ...
    }:
    let
      cfg = config.languages.rust;
      hasTreefmt = options ? treefmt;

      # Nix-managed hook script — absolute store paths, no PATH dependency.
      # Symlinked into .git/hooks/ when the repo is explicitly trusted.
      cargoBin =
        if cfg.toolchain != null then "${cfg.toolchain}/bin/cargo" else "${pkgs.cargo}/bin/cargo";

      preCommitHook = pkgs.writeShellScript "pre-commit-rust" ''
        set -e
        ${cargoBin} fmt --check || { echo "  Run 'cargo fmt' to fix formatting"; exit 1; }
        ${cargoBin} clippy -- -D warnings
      '';
    in
    {
      options.languages.rust = {
        enable = mkEnableOption "Rust language tooling";

        toolchain = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = ''
            Rust toolchain package. null → nixpkgs stable (rustc, cargo, rustfmt, clippy, rust-analyzer).

            Typical fenix usage — stable with specific components and a cross target:
              inputs.fenix.packages.''${system}.combine [
                (inputs.fenix.packages.''${system}.stable.withComponents
                  [ "rustc" "cargo" "rustfmt" "clippy" "rust-src" "rust-analyzer" "llvm-tools" ])
                inputs.fenix.packages.''${system}.targets."wasm32-unknown-unknown".stable.rust-std
              ]

            To switch channel, replace "stable" with "nightly" in both places.
            Pinned by fenix's flake.lock — no per-release sha256 required.
          '';
        };

        hooks = mkEnableOption ''
          Nix-managed pre-commit hooks (fmt + clippy).

          Hook scripts reference absolute Nix store paths — they work without the
          devshell active. Installed only when the repo is explicitly trusted:

            git config --local core.hooksPath .git/hooks   # enable  (alias: git trust)
            git config --local --unset core.hooksPath      # disable (alias: git untrust)

          This respects a global core.hooksPath=/dev/null security policy and avoids
          any dependency on git-hooks.nix or pre-commit install.
        '';

        formatters = mkEnableOption ''
          nix fmt integration via treefmt (rustfmt).
          Requires importing inputs.treefmt-nix.flakeModule in the consuming flake.
        '';

        coverage = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Include cargo-llvm-cov and lcov for code coverage.

            cargo-llvm-cov requires matching LLVM versions between the profiler tools
            and the compiler. With a fenix toolchain, include the llvm-tools component.
          '';
        };

        devShell = mkOption {
          type = types.package;
          readOnly = true;
          description = "Rust development shell, composable via inputsFrom";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          languages.rust.devShell = pkgs.mkShellNoCC {
            nativeBuildInputs =
              (
                if cfg.toolchain != null then
                  [ cfg.toolchain ]
                else
                  with pkgs; [
                    rustc
                    cargo
                    rustfmt
                    clippy
                    rust-analyzer
                  ]
              )
              ++ [
                pkgs.bacon
                pkgs.cargo-edit
                pkgs.cargo-audit
                pkgs.cargo-nextest
                pkgs.cargo-watch
              ]
              ++ optionals cfg.coverage [
                pkgs.cargo-llvm-cov
                pkgs.lcov
              ];

            shellHook = ''
              # All env vars exported here — top-level Nix attrs are NOT propagated
              # through inputsFrom, so this is the only reliable place to set them.
              export RUST_BACKTRACE=''${RUST_BACKTRACE:-full}
              export CARGO_NET_GIT_FETCH_WITH_CLI=''${CARGO_NET_GIT_FETCH_WITH_CLI:-true}
              export CARGO_HTTP_MULTIPLEXING=''${CARGO_HTTP_MULTIPLEXING:-true}
              ${
                if cfg.toolchain == null then ''
                  export RUST_SRC_PATH=''${RUST_SRC_PATH:-${pkgs.rustPlatform.rustLibSrc}}
                '' else ''
                  export RUST_SRC_PATH=''${RUST_SRC_PATH:-${cfg.toolchain}/lib/rustlib/src/rust/library}
                ''
              }

              echo "Rust development environment loaded"
              echo "Rust:  $(rustc --version)"
              echo "Cargo: $(cargo --version)"

              ${lib.optionalString cfg.hooks ''
                # Install Nix-managed hooks when the repo is explicitly trusted.
                # Trust:   git config --local core.hooksPath .git/hooks  (alias: git trust)
                # Untrust: git config --local --unset core.hooksPath     (alias: git untrust)
                if [ "$(git config --local core.hooksPath 2>/dev/null)" = ".git/hooks" ]; then
                  mkdir -p .git/hooks
                  ln -sf ${preCommitHook} .git/hooks/pre-commit
                  echo "Hooks: pre-commit (fmt + clippy) installed"
                else
                  echo "Hooks: disabled — run 'git trust' to enable"
                fi
              ''}
            '';
          };
        }

        (optionalAttrs hasTreefmt {
          treefmt.config = mkIf cfg.formatters {
            projectRootFile = lib.mkDefault "Cargo.toml";
            programs.rustfmt = {
              enable = true;
            } // optionalAttrs (cfg.toolchain != null) {
              # Use the fenix toolchain's rustfmt rather than nixpkgs rustfmt,
              # so the formatter edition matches the compiler.
              package = cfg.toolchain;
            };
          };
        })
      ]);
    }
  );
}
