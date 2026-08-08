#!/usr/bin/env bats
#
# The VS Code extensions dir this repo hands to a consumer.
#
# WHY THE MANIFEST IS ASSERTED, not just the extension dirs: `extensions.json` is a server-written INDEX,
# and the server rebuilds it only when ABSENT. Place a read-only directory without one and the server
# fails outright — `Unable to read file … extensions.json` — rather than degrading. Measured against
# code-server 1.129.1. So a packaged dir that lacks it is not "missing a nicety", it is broken.
#
# These call the flake LIB rather than the perSystem option, because a lib function is reachable with a
# plain `nix eval` and needs no consuming shell to exist first.

FLAKE_ROOT=""
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  FLAKE_ROOT=$(git rev-parse --show-toplevel)
else
  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  FLAKE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
}

# Build the packaged dir for a fixed, minimal selection so the assertions do not move when the catalog
# gains a language.
build_dir() {
  nix build --no-link --print-out-paths --impure --expr "
    let
      f = builtins.getFlake \"git+file://$FLAKE_ROOT\";
      pkgs = import f.inputs.nixpkgs { system = builtins.currentSystem; config.allowUnfree = true; };
    in f.lib.vscodeServerExtensions { inherit pkgs;
         # MULTI-element deliberately: a one-element selection cannot detect a manifest built from a
         # SUBSET, which is the stale-manifest shape. Caught by mutation — `.nix` alone has one entry,
         # so truncating the manifest to its first element left all three tests green.
         exts = with (f.lib.vscodeExtensionsFor pkgs); nix ++ rust; }
  " 2>&1
}

@test "the packaged dir carries a manifest, not just extension directories" {
  run build_dir
  assert_success
  local out="${lines[-1]}"

  assert [ -e "$out/share/vscode/extensions/extensions.json" ]
}

@test "every manifest entry names a directory that is actually present" {
  run build_dir
  assert_success
  local dir="${lines[-1]}/share/vscode/extensions"

  # Case-folds deliberately: the directory is `golang.Go` while the manifest says `golang.go`, and the
  # server resolves case-insensitively. Asserting exact case would fail on a truth about VS Code, not ours.
  run bash -c "
    python3 - <<'PY'
import json, os, sys
d = '$dir'
m = json.load(open(os.path.join(d, 'extensions.json')))
dirs = {e.lower() for e in os.listdir(d) if e != 'extensions.json'}
missing = [e['identifier']['id'] for e in m if e['identifier']['id'].lower() not in dirs]
print('missing:', missing)
sys.exit(1 if missing else 0)
PY
  "
  assert_success
}

@test "the manifest lists exactly what was declared — no more, no less" {
  run build_dir
  assert_success
  local dir="${lines[-1]}/share/vscode/extensions"

  # The property the manifest exists for: a REMOVAL must not linger. Counting both ways is what catches a
  # manifest that is generated once and then reused across a changed selection.
  run bash -c "
    python3 - <<'PY'
import json, os, sys
d = '$dir'
m = json.load(open(os.path.join(d, 'extensions.json')))
dirs = {e.lower() for e in os.listdir(d) if e != 'extensions.json'}
ids  = {e['identifier']['id'].lower() for e in m}
print('dirs:', sorted(dirs)); print('manifest:', sorted(ids))
sys.exit(0 if dirs == ids else 1)
PY
  "
  assert_success
}

# The HOME FRAGMENT: the same packaged dir, wrapped as a home-manager module a consumer can be extended
# with. Asserted against the packaging above rather than restated, because the two drifting apart is the
# failure this pairing exists to prevent.
eval_fragment_source() {
  nix eval --raw --impure --expr "
    let
      f = builtins.getFlake \"git+file://$FLAKE_ROOT\";
      pkgs = import f.inputs.nixpkgs { system = builtins.currentSystem; config.allowUnfree = true; };
      m = f.lib.vscodeServerHomeModule { inherit pkgs;
            exts = with (f.lib.vscodeExtensionsFor pkgs); nix ++ rust; };
    in m.home.file.\".vscode-server/extensions\".source
  " 2>&1
}

@test "the home fragment places the packaged dir, and places the same one" {
  run build_dir
  assert_success
  local packaged="${lines[-1]}"

  run eval_fragment_source
  assert_success

  # Equality, not "contains": a fragment pointing at a DIFFERENT env would still hold a plausible path.
  assert_equal "${lines[-1]}" "$packaged/share/vscode/extensions"
}

@test "what the fragment points at is a real directory carrying the manifest" {
  # BUILD, not just eval. `nix eval` resolves an output path without realising it, so the on-disk
  # assertions below would otherwise pass only because an earlier test in this file happened to build the
  # same derivation — green in file order, red under `--filter` or on a cold store.
  run build_dir
  assert_success

  run eval_fragment_source
  assert_success
  local placed="${lines[-1]}"

  # The subdir is the load-bearing half — `${env}` alone is one level too high and the server would find
  # no extensions at all. Asserting the string in the test above cannot catch that; existence can.
  assert [ -d "$placed" ]
  assert [ -e "$placed/extensions.json" ]
}
