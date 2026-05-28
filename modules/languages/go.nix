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

      # Nix-managed hook script — absolute store paths, no PATH dependency.
      # Symlinked into .git/hooks/ when the repo is explicitly trusted.
      preCommitHook = pkgs.writeShellScript "pre-commit-go" ''
        set -e
        ROOT=$(git rev-parse --show-toplevel)
        cd "$ROOT/${cfg.srcDir}"

        unformatted=$(${goPkgs.gofumpt}/bin/gofumpt -l .)
        if [ -n "$unformatted" ]; then
          echo "Formatting issues:"
          echo "$unformatted"
          echo "  Run 'gofumpt -w .' to fix"
          exit 1
        fi

        ${goPkgs.golangci-lint}/bin/golangci-lint run ./...
      '';
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
          Nix-managed pre-commit hooks (gofumpt + golangci-lint).

          Hook scripts reference absolute Nix store paths — they work without the
          devshell active. Installed only when the repo is explicitly trusted:

            git config --local core.hooksPath .git/hooks   # enable  (alias: git trust)
            git config --local --unset core.hooksPath      # disable (alias: git untrust)

          This respects a global core.hooksPath=/dev/null security policy and avoids
          any dependency on git-hooks.nix or pre-commit install.
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

              ${lib.optionalString cfg.hooks ''
                # Install Nix-managed hooks when the repo is explicitly trusted.
                # Trust:   git config --local core.hooksPath .git/hooks  (alias: git trust)
                # Untrust: git config --local --unset core.hooksPath     (alias: git untrust)
                # Use the git root so the hook lands in the right .git/ even when
                # the devshell is entered from a subdirectory (e.g. services/golang).
                _GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
                if [ -n "$_GIT_ROOT" ] && [ "$(git config --local core.hooksPath 2>/dev/null)" = ".git/hooks" ]; then
                  mkdir -p "$_GIT_ROOT/.git/hooks"
                  ln -sf ${preCommitHook} "$_GIT_ROOT/.git/hooks/pre-commit"
                  echo "Hooks: pre-commit (gofumpt + golangci-lint) installed"
                else
                  echo "Hooks: disabled — run 'git trust' to enable"
                fi
                unset _GIT_ROOT
              ''}
            '';
          };
        }
        # treefmt formatters (only if treefmt module is loaded)
        # treefmt passes individual files; golangci-lint needs package scope.
        # Wrap it in a script that ignores the file args and runs ./... from srcDir.
        # golangci-lint --fix applies gofumpt + gci + golines in one pass.
        (optionalAttrs hasTreefmt {
          treefmt.settings.formatter = mkIf cfg.formatters {
            golangci-lint = {
              command = toString (pkgs.writeShellScript "golangci-lint-fmt" ''
                export PATH="${goPkgs.go}/bin:$PATH"
                export CGO_ENABLED=0
                ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
                cd "$ROOT/${cfg.srcDir}"
                exec ${goPkgs.golangci-lint}/bin/golangci-lint run --fix ./...
              '');
              options = [ ];
              includes = [ "*.go" ];
            };
          };
        })
      ]);
    }
  );
}
