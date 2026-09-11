{
  description = "ci-runner session — a self-hosted GitHub Actions runner for screwyprof/devbox, declared";

  # WHY THIS IS A SESSION FLAKE AND NOT A DEVBOX CHANGE. A runner is TOOLING — the same call #225 made
  # for `claude`: the cage floor ships the mechanism, the project ships what it runs. Everything devbox
  # must provide already exists: `linger` so a project can own a long-running service (#422), the
  # `executor` egress allowlist (#446), secret staging, and the declared-home seam this flake uses.
  #
  # WHY DECLARED RATHER THAN PROVISIONED. The previous shape generated the unit with nix and INSTALLED it
  # with a script, so the unit was a regular file naming store paths that nothing rooted. A
  # `nix-collect-garbage` took `ci-runner-configure`, `ExecStartPre` failed `203/EXEC`, and the runner sat
  # offline with every workflow queued — silently, for a day. A cage cannot root its own closure
  # (`nix-store --add-root --indirect` registers the CLIENT path, which does not exist node-side).
  # Declaring the unit here puts it in the home generation, and devbox roots THAT from the node as
  # `cage-home-ci-runner` at every `up` — verified on `devbox-agentic`, whose service's `ExecStart` is
  # inside that gcroot's closure. The `root-unit` helper the old flake needed is therefore gone.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # The operator's own config, by LOCKED REF — this flake extends it and hands devbox a finished home.
    operator = {
      url = "github:screwyprof/nix-config/89c8d0fa9dbf4b222d326c7754b67bc4adc69ced";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.import-tree.follows = "nix-devx/import-tree";
    };
    # By REMOTE, not by path, even though this flake lives inside nix-devx: the lock then pins a published
    # rev and editing a module here does not silently change a running runner.
    nix-devx = {
      url = "github:screwyprof/nix-devx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {
        systems = [ "aarch64-linux" ];

        perSystem =
          { pkgs, ... }:
          {
            devShells.default = pkgs.mkShell {
              packages = [
                pkgs.github-runner
                pkgs.cachix
              ];
            };
          };

        flake.devbox.aarch64-linux.home = withSystem "aarch64-linux" (
          { pkgs, ... }:
          let
            url = "https://github.com/screwyprof/devbox";
            runner = pkgs.github-runner;

            # `RUNNER_ROOT` is the ONLY thing that decides where runner state lands; a WorkingDirectory is
            # not. nixpkgs wraps every entrypoint with `cd '<store path>'`, discarding any cd the caller
            # did — so setting a working directory is silently wrong in the worst way: `config.sh` still
            # REGISTERS into `$HOME/.github-runner`, and the next start finds neither `.runner` nor a
            # token. Measured, not guessed.
            #
            # `.local/share/github-runner` is in this project's `persist` set, so `.runner` and
            # `.credentials` survive `down`+`up` and registration stays one-time.
            runnerRoot = "%h/.local/share/github-runner";

            # The staged path for a REFERENCED secret: `0440 root:dev`, in-cage, written by `up`.
            # Wiring is `devbox sandbox secret ref ci-runner GH_RUNNER_REGISTRATION_TOKEN` — see README.
            tokenFile = "/run/devbox/secrets/GH_RUNNER_REGISTRATION_TOKEN";

            # A systemd USER unit inherits NO usable PATH, and this list is not decoration. PAM
            # `systemd-user` is deliberately excluded from devbox's session-env injection — that would hand
            # every user unit an agent-authored PATH — so nothing here comes for free.
            #
            # `grep` is load-bearing: `config.sh` shells out to `grep` and `ldd` for its libicu check, and
            # without it registration dies with `Libicu's dependencies is missing`, which names the wrong
            # cause. It works by hand ONLY because a login shell has a full PATH — which is exactly what
            # makes this class of bug survive manual testing.
            unitPath = pkgs.lib.makeBinPath [
              runner
              pkgs.bashInteractive
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gnused
              pkgs.gawk
              pkgs.findutils
              pkgs.which
              pkgs.gnutar
              pkgs.gzip
              pkgs.curl
              pkgs.git
              pkgs.nix
              pkgs.cachix
              pkgs.glibc.bin
            ];

            # THE UPSTREAM TARBALL CANNOT RUN HERE. `actions-runner-linux-arm64.tar.gz` downloads fine and
            # then dies: its scripts are `#!/bin/bash` (a cage has `/bin/sh` only) and its bundled .NET
            # wants FHS libs (`libstdc++.so.6 => not found`). `pkgs.github-runner` is the only thing that
            # executes. Measured, #445.
            #
            # `--disableupdate` is NOT optional: a nix-built runner cannot rewrite its own store path, so
            # self-update breaks it back into the tarball's failure. The version is pinned by `nixpkgs`,
            # and GitHub deprecates on its own schedule — bump the input when that bites.
            configure = pkgs.writeShellScript "ci-runner-configure" ''
              set -euo pipefail
              cd "$RUNNER_ROOT"

              # Registration is ONE-TIME. `.runner` is what `config.sh` writes on success, so its presence
              # is the idempotence check — and why no credential is needed on an ordinary restart.
              if [ -e .runner ]; then
                echo "already registered; re-authenticating from .credentials"
                exit 0
              fi

              if [ ! -s ${tokenFile} ]; then
                echo "not registered, and no token at ${tokenFile}." >&2
                echo "Mint one (~1h TTL) and stage it — see this flake's README." >&2
                exit 1
              fi

              # --no-default-labels: without it the runner ALSO claims `self-hosted`, `Linux` and `ARM64`,
              # so ANY workflow saying `runs-on: self-hosted` lands here. Measured, #445.
              #
              # A `503 github-launch service unavailable` here is GITHUB's, not this cage's: config.sh
              # retries with backoff and looks like a hang. Check githubstatus.com before debugging.
              ${runner}/bin/config.sh \
                --url ${url} \
                --token "$(cat ${tokenFile})" \
                --name ci-runner \
                --labels cage,nixos,aarch64-linux \
                --no-default-labels \
                --disableupdate \
                --unattended \
                --replace \
                --work "$RUNNER_ROOT/_work"
            '';
          in
          # `.activationPackage`, NOT the configuration attrset: devbox builds
          # `<flake>#devbox.<system>.home` DIRECTLY, so this attribute must BE the derivation. Without it
          # the build fails `'devbox.aarch64-linux.home.type' is not a string but a set` — nix reading an
          # attrset where it wants a package — and `up` falls back to the operator profile with a warning
          # rather than failing, so the runner silently loses its unit.
          (inputs.operator.homeConfigurations.devbox-cage.extendModules {
            modules = [
              {
                systemd.user.services.github-runner = {
                  Unit = {
                    Description = "GitHub Actions runner (caged)";
                    After = [ "network-online.target" ];
                    Wants = [ "network-online.target" ];
                  };

                  Service = {
                    Environment = [
                      "RUNNER_ROOT=${runnerRoot}"
                      "PATH=${unitPath}"
                    ];
                    ExecStartPre = [
                      "${pkgs.coreutils}/bin/mkdir -p ${runnerRoot}"
                      # `_work` is job scratch, never state: wiping it per start is what keeps one job's
                      # checkout, build output and stray dotfiles from being visible to the next. It is
                      # per START, not per job — jobs within one service lifetime still share it, which is
                      # why a PR job and a key-bearing job must not share a runner (#445).
                      "${pkgs.coreutils}/bin/rm -rf ${runnerRoot}/_work"
                      "${configure}"
                    ];
                    # `--disableupdate` is NOT accepted here — `run` rejects it with "Unrecognized
                    # command-line input arguments". It is a `config.sh` option, recorded as
                    # `disableUpdate` in `.runner` at registration.
                    ExecStart = "${runner}/bin/Runner.Listener run --startuptype service";
                    WorkingDirectory = runnerRoot;
                    Restart = "always";
                    RestartSec = "5s";
                  };

                  Install.WantedBy = [ "default.target" ];
                };
              }
            ];
          }).activationPackage
        );
      }
    );
}
