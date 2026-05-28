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
      hasTreefmt = options ? treefmt;
      hasPreCommit = options ? pre-commit;

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

        srcDir = mkOption {
          type = types.str;
          default = ".";
          description = ''
            Path to the Go source directory relative to the git repository root.
            Used by hooks to locate the go.mod when Go lives in a subdirectory.
          '';
        };

        gopath = mkOption {
          type = types.str;
          default = "\${XDG_DATA_HOME:-$HOME/.local/share}/go";
          description = "Go path for module cache";
        };

        formatters = mkEnableOption "recommended treefmt formatters for Go";

        hooks = mkEnableOption ''
          Pre-commit hooks (gofumpt + golangci-lint) via git-hooks.nix.
          Requires importing inputs.git-hooks.flakeModule in the consuming flake.
        '';

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
              export GOPATH=''${GOPATH:-${cfg.gopath}}
              mkdir -p "$GOPATH/pkg/mod"

              echo "Go development environment loaded"
              echo "Go version: $(go version)"
              echo "GOPATH: $GOPATH"
            '';
          };
        }
        # treefmt formatters (only if treefmt module is loaded)
        # treefmt passes individual files; golangci-lint needs package scope.
        # Wrap it in a script that ignores the file args and runs ./... from srcDir.
        # golangci-lint --fix applies gofumpt + gci + golines in one pass.
        (optionalAttrs hasPreCommit {
          pre-commit.settings.hooks = mkIf cfg.hooks {
            gofumpt = {
              enable = true;
              name = "gofumpt";
              entry = "${goPkgs.gofumpt}/bin/gofumpt -l -w";
              language = "system";
              types = [ "go" ];
            };
            golangci-lint = {
              enable = true;
              name = "golangci-lint";
              entry = toString (
                pkgs.writeShellScript "golangci-lint-hook" ''
                  export PATH="${goPkgs.go}/bin:$PATH"
                  export CGO_ENABLED=0
                  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
                  cd "$ROOT/${cfg.srcDir}"
                  exec ${goPkgs.golangci-lint}/bin/golangci-lint run ./...
                ''
              );
              language = "system";
              types = [ "go" ];
              pass_filenames = false;
            };
          };
        })
        (optionalAttrs hasTreefmt {
          treefmt.settings.formatter = mkIf cfg.formatters {
            golangci-lint = {
              command = toString (
                pkgs.writeShellScript "golangci-lint-fmt" ''
                  export PATH="${goPkgs.go}/bin:$PATH"
                  export CGO_ENABLED=0
                  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
                  cd "$ROOT/${cfg.srcDir}"
                  exec ${goPkgs.golangci-lint}/bin/golangci-lint run --fix ./...
                ''
              );
              options = [ ];
              includes = [ "*.go" ];
            };
          };
        })
      ]);
    }
  );
}
