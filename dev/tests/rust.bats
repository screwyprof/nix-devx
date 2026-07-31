#!/usr/bin/env bats
#
# NOTE ON ASSERTIONS: these use `assert_line`, not `assert_output`.
#
# The rust devShell deliberately prints a banner ("Rust development environment loaded", versions),
# and dev/tests/templates.bats DEPENDS on it — it asserts that banner as the signal the environment
# loaded. bats' `run` merges stdout and stderr into one `$output`, so an exact `assert_output "full"`
# can never match: it sees the banner plus the value. That is why these five assertions failed from
# the day they were written (the echoes predate this file by three months).
#
# So the shell is right and the assertion was wrong. The fix asserts the LAST line exactly: the banner
# is printed when the shell is entered, the command runs after it, so `${lines[-1]}` IS the echoed
# value. That keeps the check exact — a wrong value, an empty value, or the value appearing anywhere
# but where the command wrote it all still fail. (A bare `assert_line "full"` would NOT: it only says
# some line somewhere equals it.)
#
# Do not silence the banner to allow `assert_output` here — that would take `make test` red, and only
# once published, since the templates pin the upstream flake.
#
# NOTE ON `env -u`: the OUTER dev shell already exports RUST_BACKTRACE and CARGO_* , so a plain
# invocation inherits them and passes even when the module exports nothing — verified by deleting the
# export and watching these tests stay green. Clearing the variable first is what makes the assertion
# about THIS MODULE rather than about inheritance.
# Integration tests for the rust module

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
  TEST_DIR=$(mktemp -d -t nix-devx-rust-XXXXXX)
  export TEST_DIR
}

teardown() {
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# ---------------------------------------------------------------------------
# Tool availability
# ---------------------------------------------------------------------------

@test "rust: rustc is available" {
  run nix develop "$FLAKE_ROOT#rust-test" --command rustc --version
  assert_success
}

@test "rust: cargo is available" {
  run nix develop "$FLAKE_ROOT#rust-test" --command cargo --version
  assert_success
}

@test "rust: bacon is available" {
  run nix develop "$FLAKE_ROOT#rust-test" --command bacon --version
  assert_success
}

@test "rust: cargo-nextest is available" {
  run nix develop "$FLAKE_ROOT#rust-test" --command cargo nextest --version
  assert_success
}

# ---------------------------------------------------------------------------
# Environment variables in direct shell
# ---------------------------------------------------------------------------

@test "rust: RUST_BACKTRACE is exported" {
  run env -u RUST_BACKTRACE nix develop "$FLAKE_ROOT#rust-test" --command bash -c 'echo "$RUST_BACKTRACE"'
  assert_success
  assert_equal "${lines[-1]}" "full"
}

@test "rust: CARGO_HTTP_MULTIPLEXING is exported (correct spelling)" {
  run env -u CARGO_HTTP_MULTIPLEXING nix develop "$FLAKE_ROOT#rust-test" --command bash -c 'echo "$CARGO_HTTP_MULTIPLEXING"'
  assert_success
  assert_equal "${lines[-1]}" "true"
}

@test "rust: CARGO_NET_GIT_FETCH_WITH_CLI is exported" {
  run env -u CARGO_NET_GIT_FETCH_WITH_CLI nix develop "$FLAKE_ROOT#rust-test" --command bash -c 'echo "$CARGO_NET_GIT_FETCH_WITH_CLI"'
  assert_success
  assert_equal "${lines[-1]}" "true"
}

# ---------------------------------------------------------------------------
# inputsFrom propagation — the key regression test
# ---------------------------------------------------------------------------

@test "rust: RUST_BACKTRACE propagates through inputsFrom" {
  run env -u RUST_BACKTRACE nix develop "$FLAKE_ROOT#rust-nested" --command bash -c 'echo "$RUST_BACKTRACE"'
  assert_success
  assert_equal "${lines[-1]}" "full"
}

@test "rust: CARGO_HTTP_MULTIPLEXING propagates through inputsFrom" {
  run env -u CARGO_HTTP_MULTIPLEXING nix develop "$FLAKE_ROOT#rust-nested" --command bash -c 'echo "$CARGO_HTTP_MULTIPLEXING"'
  assert_success
  assert_equal "${lines[-1]}" "true"
}

@test "rust: cargo is available in nested shell" {
  run nix develop "$FLAKE_ROOT#rust-nested" --command cargo --version
  assert_success
}
