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
      cfg = config.languages.go;
      hasPreCommit = options ? pre-commit;
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

        hooks = mkEnableOption "recommended git hooks for Go";
      };

      config = mkIf cfg.enable (mkMerge [
        {
          # Self-contained Go devShell
          devShells.go = pkgs.mkShellNoCC {
            nativeBuildInputs = with pkgs; [
              go
              gopls
              delve
              gotools
              golangci-lint
              gofumpt
              golines
              gci
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
        }
        (optionalAttrs hasPreCommit {
          # Configure git hooks (only if hooks.enable is true AND pre-commit module is loaded)
          pre-commit.settings.hooks = mkIf cfg.hooks {
            golangci-lint = {
              enable = true;
              types_or = [ "go" ];
            };
          };
        })
      ]);
    }
  );
}
