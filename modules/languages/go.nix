{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
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

        gobin = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Go bin directory (null for per-project directory)";
        };

        gopath = mkOption {
          type = types.str;
          default = "\${XDG_DATA_HOME:-$HOME/.local/share}/go";
          description = "Go path for module cache";
        };
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
        # pre-commit.settings.hooks = {
        #   gofmt.enable = true;
        #   go-mod-tidy.enable = true;
        #   golangci-lint.enable = true;
        #   golangci-lint-types = true;
        # };

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

          # needed for delve to work
          hardeningDisable = [ "all" ];

          shellHook = ''
            # Project root & stable hash
            PROJECT_ROOT=''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
            PROJECT_HASH=''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}

            # Shared module cache
            export GOPATH=''${GOPATH:-${cfg.gopath}}
            ${
              if cfg.gobin != null then
                ''
                  # Use custom GOBIN
                  export GOBIN=''${GOBIN:-${cfg.gobin}}
                ''
              else
                ''
                  # Use per-project GOBIN with project hash
                  export GOBIN=''${GOBIN:-''${XDG_STATE_HOME:-$HOME/.local/state}/go-bin-$PROJECT_HASH}
                ''
            }
            export PATH="$GOBIN:$PATH"

            # Create directories
            mkdir -p "$GOPATH/pkg/mod" "$GOBIN"

            echo "Go development environment loaded"
            echo "Go version: $(go version)"
            echo "GOPATH: $GOPATH"
            echo "GOBIN: $GOBIN"
            echo "Project root: $PROJECT_ROOT"
            echo "Project hash: $PROJECT_HASH"
          '';
        };
      };
    }
  );
}
