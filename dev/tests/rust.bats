#!/usr/bin/env bats
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
  run nix develop "$FLAKE_ROOT#rust-test" --command bash -c 'echo "$RUST_BACKTRACE"'
  assert_success
  assert_output "full"
}

@test "rust: CARGO_HTTP_MULTIPLEXING is exported (correct spelling)" {
  run nix develop "$FLAKE_ROOT#rust-test" --command bash -c 'echo "$CARGO_HTTP_MULTIPLEXING"'
  assert_success
  assert_output "true"
}

@test "rust: CARGO_NET_GIT_FETCH_WITH_CLI is exported" {
  run nix develop "$FLAKE_ROOT#rust-test" --command bash -c 'echo "$CARGO_NET_GIT_FETCH_WITH_CLI"'
  assert_success
  assert_output "true"
}

# ---------------------------------------------------------------------------
# inputsFrom propagation — the key regression test
# ---------------------------------------------------------------------------

@test "rust: RUST_BACKTRACE propagates through inputsFrom" {
  run nix develop "$FLAKE_ROOT#rust-nested" --command bash -c 'echo "$RUST_BACKTRACE"'
  assert_success
  assert_output "full"
}

@test "rust: CARGO_HTTP_MULTIPLEXING propagates through inputsFrom" {
  run nix develop "$FLAKE_ROOT#rust-nested" --command bash -c 'echo "$CARGO_HTTP_MULTIPLEXING"'
  assert_success
  assert_output "true"
}

@test "rust: cargo is available in nested shell" {
  run nix develop "$FLAKE_ROOT#rust-nested" --command cargo --version
  assert_success
}
