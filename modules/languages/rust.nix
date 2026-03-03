{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
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

        cargoHome = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Cargo home directory (null for per-project directory)";
        };

        toolchain = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = "Rust toolchain package (null for default rustc)";
        };

        hooks = mkEnableOption "recommended git hooks for Rust";
      };

      config = mkIf cfg.enable (mkMerge [
        {
          # Self-contained Rust devShell
          devShells.rust = pkgs.mkShellNoCC {
            nativeBuildInputs =
              (
                if cfg.toolchain != null then
                  [ cfg.toolchain ]
                else
                  [
                    pkgs.rustc
                    pkgs.cargo
                  ]
              )
              ++ (with pkgs; [
                # Cargo extensions
                bacon
                cargo-edit
                cargo-audit
                cargo-binutils
                cargo-nextest
                cargo-watch

                # Coverage tools
                lcov

                # Linters
                checkmake
              ]);

            # Environment variables
            RUST_BACKTRACE = "full";
            CARGO_NET_GIT_FETCH_WITH_CLI = "true";
            CARGO_HTTP_MULTIPLEXING = "true";

            # Shell initialization
            shellHook = ''
              # Project root & stable hash
              PROJECT_ROOT=''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
              PROJECT_HASH=''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}

              # Project-specific cargo directory (state/cache data)
              ${
                if cfg.cargoHome != null then
                  ''
                    # Use custom CARGO_HOME
                    export CARGO_HOME=''${CARGO_HOME:-${cfg.cargoHome}}
                  ''
                else
                  ''
                    # Use per-project CARGO_HOME with project hash
                    export CARGO_HOME=''${CARGO_HOME:-''${XDG_STATE_HOME:-$HOME/.local/state}/cargo-$PROJECT_HASH}
                  ''
              }
              export CARGO_TARGET_DIR="$CARGO_HOME/target"
              export PATH="$CARGO_HOME/bin:$PATH"

              # Create directories
              mkdir -p "$CARGO_HOME/bin"

              echo "Rust development environment loaded"
              echo "Rust version: $(rustc --version)"
              echo "Cargo version: $(cargo --version)"
              echo "CARGO_HOME: $CARGO_HOME"
              echo "Project root: $PROJECT_ROOT"
              echo "Project hash: $PROJECT_HASH"

              # Check if project has its own toolchain
              if [[ -f "rust-toolchain.toml" ]]; then
                echo "Project toolchain detected:"
                if grep -q "channel" rust-toolchain.toml; then
                  CHANNEL=$(grep "channel" rust-toolchain.toml | cut -d= -f2 | tr -d ' "')
                  echo "   Channel: $CHANNEL"
                fi
                if grep -q "version" rust-toolchain.toml; then
                  VERSION=$(grep "version" rust-toolchain.toml | cut -d= -f2 | tr -d ' "')
                  echo "   Version: $VERSION"
                fi
                echo "   To use project toolchain: rustup toolchain install $(grep -o 'channel.*' rust-toolchain.toml | cut -d= -f2 | tr -d ' "')"
              fi

              # Install cargo-llvm-cov if not available (cached check)
              CARGO_LLVM_COV_MARKER="$CARGO_HOME/.cargo-llvm-cov-installed"
              if [[ ! -f "$CARGO_LLVM_COV_MARKER" ]]; then
                echo "Installing cargo-llvm-cov..."
                cargo install cargo-llvm-cov --quiet && touch "$CARGO_LLVM_COV_MARKER"
              fi

              # Show useful tools
              echo ""
              echo "Available tools:"
              echo "  bacon          - cargo check runner"
              echo "  cargo-nextest  - next-gen test runner"
              echo "  cargo-llvm-cov - code coverage"
              echo "  cargo-audit    - security audit"
            '';
          };
        }
        (optionalAttrs hasPreCommit {
          # Configure git hooks (only if hooks.enable is true AND pre-commit module is loaded)
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
