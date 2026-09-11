# devbox session flakes

A devbox project can point its `session_flake` at a directory holding a flake that declares the
project's home:

```
flake.devbox.<system>.home = <operator home>.extendModules { modules = [ … ]; }).activationPackage;
```

devbox builds that attribute at every `sandbox up`, activates it in the cage, and plants a node-side
gcroot for it (`cage-home-<slug>`). That gcroot is why a session flake belongs in a repo rather than
in a script: **a cage cannot root its own closure**, so anything it installs by hand is collectable,
and a `nix-collect-garbage` turns it into `203/EXEC` at the next start.

They live here rather than in `nix-config` because this is where reusable nix tooling lives; a
session flake configures a *project's* environment, not a *machine's*.

`devbox.<system>.home` must **be** the derivation — `.activationPackage`, not the home-manager
configuration attrset. Handing over the attrset fails with
`'devbox.<system>.home.type' is not a string but a set`, and `up` only warns.

## Using one

Copy the directory into the project's `session/` tree on the node and point the project at it. `--flake`
takes an absolute path and is **persisted**, so a later bare `up` reuses it — there is no manifest to
hand-edit:

```
sudo mkdir -p /work/projects/<name>/session
sudo install -o root -g root -m 644 <this dir>/<name>/flake.nix <this dir>/<name>/flake.lock \
  /work/projects/<name>/session/
devbox sandbox down <name>
devbox sandbox up <name> --flake /work/projects/<name>/session
```

`install` rather than `cp`, because the modes are DECLARED: the tree must end up `root:root` for the
reason below, and `cp` would carry whatever the source happened to have.

The `session/` tree is `root:root` on the node and reaches the cage **read-only**, at
`/run/devbox/flake` — so the occupant can read the thing that defines its own environment and cannot
change it. That is also why this is a copy rather than a checkout: nothing in the cage can `git pull`
into a read-only bind, so updating it is a node-side act.

| flake | what it is |
|---|---|
| [`ci-runner`](ci-runner/) | the self-hosted GitHub Actions runner for `screwyprof/devbox` |
