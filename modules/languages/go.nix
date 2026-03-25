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
      hasTreefmt = options ? treefmt;

      # gci v0.13.x is broken with Go 1.26 due to linkname checks; use v0.14.0
      goPkgs = pkgs.extend (
        _final: prev: {
          gci = prev.gci.overrideAttrs (old: {
            version = "0.14.0";
            src = prev.fetchFromGitHub {
              owner = "daixiang0";
              repo = "gci";
              rev = "v0.14.0";
              hash = "sha256-+qoHORHUMgr03v3RB+7+g9O/tlDkQKFmKybma0FdhVs=";
            };
            vendorHash = "sha256-MS6Ei58HpR/ueqdmGEx15WoSSSwDpQUcxAWz36UnhmA=";
            subPackages = [ "." ];
            meta = old.meta // {
              broken = false;
            };
          });
        }
      );
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

        formatters = mkEnableOption "recommended treefmt formatters for Go";

        hooks = mkEnableOption "recommended git hooks for Go";

        devShell = mkOption {
          type = types.package;
          readOnly = true;
          description = "Go development shell";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          # Self-contained Go devShell
          languages.go.devShell = goPkgs.mkShellNoCC {
            nativeBuildInputs = with goPkgs; [
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
        # treefmt formatters (only if treefmt module is loaded)
        (optionalAttrs hasTreefmt {
          treefmt.programs = mkIf cfg.formatters {
            golangci-lint.enable = true;
          };
        })
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
