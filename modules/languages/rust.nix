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
      hasPreCommit = options ? pre-commit;

      cargoBin =
        if cfg.toolchain != null then "${cfg.toolchain}/bin/cargo" else "${pkgs.cargo}/bin/cargo";

      # cargo finds subcommands (fmt, clippy) via PATH, not via the cargo binary path.
      # Export the toolchain bin dir so cargo-fmt and cargo-clippy are resolvable.
      toolchainBin = if cfg.toolchain != null then "${cfg.toolchain}/bin" else "${pkgs.cargo}/bin";

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
          Pre-commit hooks (cargo fmt + clippy) via git-hooks.nix.
          Requires importing inputs.git-hooks.flakeModule in the consuming flake.
        '';

        formatters = mkEnableOption ''
          nix fmt integration via treefmt (rustfmt).
          Requires importing inputs.treefmt-nix.flakeModule in the consuming flake.
        '';

        cargoHome = mkOption {
          type = types.str;
          default = "\${XDG_DATA_HOME:-$HOME/.local/share}/cargo";
          description = "Cargo home directory (registry cache, credentials, installed binaries)";
        };

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
                  with pkgs;
                  [
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
              export CARGO_HOME=''${CARGO_HOME:-${cfg.cargoHome}}
              mkdir -p "$CARGO_HOME"
              export RUST_BACKTRACE=''${RUST_BACKTRACE:-full}
              export CARGO_NET_GIT_FETCH_WITH_CLI=''${CARGO_NET_GIT_FETCH_WITH_CLI:-true}
              export CARGO_HTTP_MULTIPLEXING=''${CARGO_HTTP_MULTIPLEXING:-true}
              ${
                if cfg.toolchain == null then
                  ''
                    export RUST_SRC_PATH=''${RUST_SRC_PATH:-${pkgs.rustPlatform.rustLibSrc}}
                  ''
                else
                  ''
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
          pre-commit.settings.hooks = mkIf cfg.hooks {
            cargo-fmt = {
              enable = true;
              name = "cargo fmt";
              entry = toString (
                pkgs.writeShellScript "cargo-fmt-hook" ''
                  export PATH="${toolchainBin}:$PATH"
                  exec ${cargoBin} fmt --check
                ''
              );
              language = "system";
              types = [ "rust" ];
              pass_filenames = false;
            };
            clippy = {
              enable = true;
              name = "clippy";
              entry = toString (
                pkgs.writeShellScript "clippy-hook" ''
                  export PATH="${toolchainBin}:$PATH"
                  exec ${cargoBin} clippy -- -D warnings
                ''
              );
              language = "system";
              types = [ "rust" ];
              pass_filenames = false;
            };
          };
        })
        (optionalAttrs hasTreefmt {
          treefmt.config = mkIf cfg.formatters {
            programs.rustfmt = {
              enable = true;
            }
            // optionalAttrs (cfg.toolchain != null) {
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
