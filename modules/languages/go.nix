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

      # Every tool is built with cfg.package. nixpkgs builds gopls with
      # buildGoLatestModule and golangci-lint with buildGo1NNModule, so rewrite
      # whichever buildGo*Module argument a package takes rather than naming it.
      buildGoModule = pkgs.buildGoModule.override { go = cfg.package; };
      withGo =
        pkg:
        pkg.override (
          args:
          lib.mapAttrs (_: _: buildGoModule) (
            lib.filterAttrs (n: _: builtins.match "buildGo(Latest|[0-9]+)?Module" n != null) args
          )
          // lib.optionalAttrs (args ? go) { go = cfg.package; }
        );

      goPkgs = pkgs.extend (
        _final: prev: {
          go = cfg.package;
          gopls = withGo prev.gopls;
          delve = withGo prev.delve;
          gotools = withGo prev.gotools;
          golangci-lint = withGo prev.golangci-lint;
          gofumpt = withGo prev.gofumpt;
          golines = withGo prev.golines;
          # gci v0.13.x is broken with Go 1.26 due to linkname checks; use v0.14.0
          gci = (withGo prev.gci).overrideAttrs (old: {
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

        package = mkOption {
          type = types.package;
          default = pkgs.go;
          defaultText = lib.literalExpression "pkgs.go";
          example = lib.literalExpression "pkgs.go_1_26";
          description = ''
            Go toolchain for the shell, hooks and formatters. gopls, delve, gotools,
            golangci-lint, gofumpt, golines and gci are rebuilt with it.
          '';
        };

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
              # Never switch away from cfg.package (nixpkgs' go.env says auto).
              # Exported here, not via env: inputsFrom merges shellHook, drops env.
              export GOTOOLCHAIN=local
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
              # git-hooks.nix puts the hook package on every devShell PATH; its
              # default is pkgs.golangci-lint, built with a different Go.
              package = goPkgs.golangci-lint;
              entry = toString (
                pkgs.writeShellScript "golangci-lint-hook" ''
                  export PATH="${goPkgs.go}/bin:$PATH"
                  export CGO_ENABLED=0 GOTOOLCHAIN=local
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
            gofumpt = {
              command = "${goPkgs.gofumpt}/bin/gofumpt";
              options = [ "-w" ];
              includes = [ "*.go" ];
            };
            golangci-lint = {
              command = toString (
                pkgs.writeShellScript "golangci-lint-fmt" ''
                  export PATH="${goPkgs.go}/bin:$PATH"
                  export CGO_ENABLED=0 GOTOOLCHAIN=local
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
