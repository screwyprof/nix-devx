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
      hasPreCommit = options ? pre-commit;
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

        hooks = mkEnableOption "recommended git hooks (rustfmt, cargo-check, clippy)";

        coverage = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Include cargo-llvm-cov and lcov for code coverage.

            cargo-llvm-cov calls llvm-profdata/llvm-cov from the Rust toolchain sysroot,
            so the LLVM version in the toolchain must match the compiler.

            With the nixpkgs default toolchain this is always satisfied.
            With a fenix toolchain, include the llvm-tools component:
              inputs.fenix.packages.''${system}.stable.withComponents
                [ "rustc" "cargo" "rustfmt" "clippy" "rust-src" "rust-analyzer" "llvm-tools" ]
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
            '';
          };
        }
        (optionalAttrs hasPreCommit {
          # pre-commit.settings.src must be set by the consumer to the Rust source root.
          # For a single-crate project: inputs.nix-filter.lib.filter { root = ./.; ... }
          # For a workspace subdirectory: adjust root to the crate or workspace path.
          pre-commit.settings.hooks = mkIf cfg.hooks {
            rustfmt.enable = true;
            cargo-check.enable = true;
            clippy.enable = true;
          };
        })
      ]);
    }
  );
}
