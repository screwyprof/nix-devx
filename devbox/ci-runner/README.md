# ci-runner — a declared GitHub Actions runner in a devbox cage

The session flake for the `ci-runner` project. It extends the operator's cage home with one
`systemd.user.service`, so devbox places and roots the runner at every `up`. There is nothing to
provision by hand.

Point the project at it once:

```
sudo jq '.session_flake = "/work/projects/ci-runner/session"' \
  /work/projects/ci-runner/.devbox/manifest.json > /tmp/m && sudo mv /tmp/m /work/projects/ci-runner/.devbox/manifest.json
```

(The `session/` tree is `root:root` on the node and reaches the cage **read-only** at
`/run/devbox/flake`, so the occupant can read the thing that defines its own runner and cannot change
it.)

## Registering — the one manual step

A runner registers **once**. `config.sh` writes `.runner` and `.credentials` into
`~/.local/share/github-runner`, which is in this project's `persist` set, so both survive `down`+`up`
and every later start re-authenticates from `.credentials` with no credential present.

So a token is needed only on **first registration**, or after a deliberate re-registration.

### 1. Mint a registration token

It has a **~1 hour TTL** and is single-use. This needs the operator's own GitHub credential — the
delivered fine-grained PAT is scoped to `screwyprof/devbox` with Actions read only and **cannot** mint
one:

```
gh api -X POST repos/screwyprof/devbox/actions/runners/registration-token --jq .token
```

If `gh` in your shell is using the delivered PAT (`GH_TOKEN` set), use the operator login instead:

```
env -u GH_TOKEN GH_CONFIG_DIR=/home/happygopher.guest/.config/gh \
  gh api -X POST repos/screwyprof/devbox/actions/runners/registration-token --jq .token
```

### 2. Stage it as a devbox secret

```
devbox sandbox secret set  GH_RUNNER_REGISTRATION_TOKEN      # reads the VALUE from stdin
devbox sandbox secret ref  ci-runner GH_RUNNER_REGISTRATION_TOKEN
devbox sandbox down ci-runner && devbox sandbox up ci-runner  # refs take effect on the next up
```

`up` stages it at `/run/devbox/secrets/GH_RUNNER_REGISTRATION_TOKEN`, `0440 root:dev`, which is the path
the unit reads. It is **not** `/work/.devbox/secrets/…` — that is the custody store, root-owned on the
node and deliberately never bound into a cage.

### 3. Check it took

```
devbox sandbox ssh ci-runner -- systemctl --user is-active github-runner.service
env -u GH_TOKEN GH_CONFIG_DIR=/home/happygopher.guest/.config/gh \
  gh api repos/screwyprof/devbox/actions/runners --jq '.runners[] | "\(.name)=\(.status)"'
```

### 4. Unref the token

The token is spent and expired within the hour. Leaving it staged serves nothing:

```
devbox sandbox secret unref ci-runner GH_RUNNER_REGISTRATION_TOKEN
```

**Why a registration token and not a PAT.** `--ephemeral` (deregister after each job) would need an
`Administration: read & write` PAT staged permanently — and a staged secret is `0440 root:dev` while
**jobs run as `dev`**, so every job could read a repo-admin token. Registering once from a ~1h
single-use token does not. The exposure is bounded to the window between staging and unreffing, and
the worst a leak buys is registering another runner for one hour.

## Re-registering

Delete the state and repeat the steps above:

```
devbox sandbox ssh ci-runner -- rm -f ~/.local/share/github-runner/.runner \
                                      ~/.local/share/github-runner/.credentials
```

`--replace` is already passed, so a name collision with the existing registration is handled.

## What this project persists, and why it must

`.devbox/manifest.json` lists:

| entry | why |
|---|---|
| `.local/share/github-runner` | `.runner`, `.credentials`, `.credentials_rsaparams`, `.path`, `.env` — the registration. Losing it means re-registering. Those are **files**, and a `persist` entry must be a directory, so the whole tree is listed and `_work` rides along |
| ~~`.config/systemd`~~ | **removed when this flake landed.** The unit is a store symlink home-manager re-places at every `up`, so persisting it serves nothing. It was required only while the unit was a hand-placed file |
| `.claude`, `.config/GitHub` | agent memory; the runner's own `ActionsService` state |

## Gotchas, each of which cost a debugging cycle

- **`RUNNER_ROOT` is the only thing that decides where state lands.** nixpkgs' wrapper `cd`s into its own
  store path, so a `WorkingDirectory` is silently ignored: `config.sh` registers into
  `$HOME/.github-runner` and the next start finds nothing.
- **A user unit inherits no usable PATH.** `config.sh` shells out to `grep`/`ldd` for its libicu check;
  without `grep` it fails with `Libicu's dependencies is missing`, naming the wrong cause. It works by
  hand only because a login shell has a full PATH.
- **`--disableupdate` is a `config.sh` option.** `run` rejects it outright. The version is pinned by the
  `nixpkgs` input, and a nix-built runner cannot self-update because it cannot rewrite its store path —
  so GitHub's deprecation schedule becomes an input bump you must land or CI stops.
- **`--no-default-labels`** — without it the runner also claims `self-hosted`, `Linux` and `ARM64`, so any
  workflow with `runs-on: self-hosted` lands here.
- **The upstream tarball cannot run in a cage** — `#!/bin/bash` (a cage has `/bin/sh`) and FHS libs for
  its bundled .NET. `pkgs.github-runner` is the only thing that executes.
- **A `503 github-launch service unavailable` during registration is GitHub's**, not the cage's.
  `config.sh` retries with backoff and looks like a hang — check githubstatus.com first.
- **A hand-placed unit left over from the old shape BLOCKS activation**, and `up` fail-opens on it:
  `Existing file '…/github-runner.service' would be clobbered`, then `home not applied`, then the cage
  starts anyway on whatever the old unit was. Migrating means deleting the durable
  `home/.config/systemd` tree AND dropping it from `persist` — the warning is the only signal.
- **Do not `systemctl --user disable` it.** The unit is a store symlink now; remove it from this flake
  instead. (The previous shape installed a regular file precisely because `disable` unlinks a symlink —
  that constraint does not apply when every `up` re-places it.)

## Egress

`ci-runner` runs the `executor` profile, whose allowlist already carries the four names the runner
needs (#446): `actions.githubusercontent.com` (control plane), the account-scoped
`r2.cloudflarestorage.com` bucket, `cachix.org`, and `channels.nixos.org`. `cachix.org` alone is not
enough — the API is `cachix.org` but NAR bodies go to R2, so a push authenticates, prints
`Pushing 1 paths`, retries three times and dies.

## Do not give this runner the signing key

`ci.yml` executes `pull_request` code here. `build.yml` carries `CACHIX_SIGNING_KEY` and runs on a hosted
runner for that reason. On one runner they are the **same `dev` user in the same cage**, so PR code could
read the key from the next job's environment — and via that key sign an artifact every VM substitutes and
runs as root at the next `vm apply`. Caging does not mitigate it: the cage bounds movement to the node,
not reading a secret in its own environment.
