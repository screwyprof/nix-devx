{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.languages.go;
    in
    {
      options.languages.go = {
        enable = mkEnableOption "Go language tooling";
      };

      config = mkIf cfg.enable {
        packages = {
          inherit (pkgs)
            go
            gopls
            delve
            gotools
            golangci-lint
            ;
        };

        # Configure git-hooks settings (used for checks)
        pre-commit.settings.hooks = {
          gofmt.enable = true;
          go-mod-tidy.enable = true;
          golangci-lint.enable = true;
          golangci-lint-types = true;
        };

        # Self-contained Go devShell
        devShells.go = pkgs.mkShellNoCC {
          buildInputs = with pkgs; [
            go
            gopls
            delve
            gotools
            golangci-lint
            gnumake
          ];

          shellHook = ''
            # Project root & stable hash
            PROJECT_ROOT=''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
            PROJECT_HASH=''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}

            # Shared module cache + per-project binaries
            export GOPATH=''${XDG_DATA_HOME:-$HOME/.local/share}/go
            export GOBIN=''${XDG_STATE_HOME:-$HOME/.local/state}/go-bin-$PROJECT_HASH
            export PATH="$GOBIN:$PATH"

            # Create directories
            mkdir -p "$GOPATH/pkg/mod" "$GOBIN"

            echo "Go development environment loaded"
            echo "Go version: $(go version)"
            echo "GOPATH: $GOPATH"
            echo "GOBIN: $GOBIN"
            echo "Project root: $PROJECT_ROOT"
          '';
        };
      };
    }
  );
}
