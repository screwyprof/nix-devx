#!/usr/bin/env bats
#
# Integration tests for the go module. Assertions read the LAST line: the shell prints a banner when
# it is entered (see rust.bats for why assert_output can't be used).

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

# Prints "<tool>: <go version it was built with>" for a tool on the go-test shell's PATH, resolved
# to its binary (gotools wraps some of its binaries in scripts).
built_with() {
  nix develop "$FLAKE_ROOT#go-test" --command bash -c '
    bin=$(readlink -f "$(command -v "$1")")
    wrapped="$(dirname "$bin")/.$(basename "$bin")-wrapped"
    [ -x "$wrapped" ] && bin=$wrapped
    go version "$bin" | sed "s/^.*: //"' _ "$1"
}

shell_go() {
  nix develop "$FLAKE_ROOT#go-test" --command go env GOVERSION
}

@test "go: every analysis tool is built with the shell's Go" {
  run shell_go
  assert_success
  want="${lines[-1]}"

  for tool in gopls dlv golangci-lint gofumpt golines gci goimports; do
    run built_with "$tool"
    assert_success
    assert_equal "$tool: ${lines[-1]}" "$tool: $want"
  done
}

@test "go: GOTOOLCHAIN is local" {
  run env -u GOTOOLCHAIN nix develop "$FLAKE_ROOT#go-test" --command go env GOTOOLCHAIN
  assert_success
  assert_equal "${lines[-1]}" "local"
}
