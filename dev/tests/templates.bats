#!/usr/bin/env bats
# Integration tests for nix-devx templates

# Find flake root (git repo root or script parent dir)
FLAKE_ROOT=""
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  FLAKE_ROOT=$(git rev-parse --show-toplevel)
else
  # Fall back to script location if not in git
  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  FLAKE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  # Create temporary directory for each test
  TEST_DIR=$(mktemp -d -t nix-devx-test-XXXXXX)
  export TEST_DIR
}

teardown() {
  # Clean up temporary directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

@test "minimal initializes successfully" {
  cd "$TEST_DIR"

  run nix flake init -t "$FLAKE_ROOT#minimal"
  run nix flake lock
  run nix develop --command true

  assert_success
  assert_output --partial 'Minimal development environment'
}

@test "go initializes successfully" {
  cd "$TEST_DIR"

  run nix flake init -t "$FLAKE_ROOT#go"
  run nix flake lock
  
  nix develop --command go version
  nix develop --command golangci-lint version
  run nix develop --command true
 
  assert_success
  assert_output --partial 'Go development environment'
}

@test "rust initializes successfully" {
  cd "$TEST_DIR"

  run nix flake init -t "$FLAKE_ROOT#rust"
  run nix flake lock
  
  nix develop --command rustc --version
  nix develop --command cargo version
  run nix develop --command true

  assert_success
  assert_output --partial 'Rust development environment'
}

@test "nix initializes successfully" {
  cd "$TEST_DIR"

  run nix flake init -t "$FLAKE_ROOT#nix"
  run nix flake lock
  
  nix develop --command statix --version
  nix develop --command deadnix --version
  run nix develop --command true

  assert_success
  assert_output --partial 'Nix development environment'
}

@test "claude initializes successfully" {
  cd "$TEST_DIR"

  run nix flake init -t "$FLAKE_ROOT#claude"
  run nix flake lock

  nix develop --command claude --version
  run nix develop --command true

  assert_success
  assert_output --partial 'Claude Code Development Environment'
}

@test "claude-unrestricted shell works" {
  cd "$FLAKE_ROOT/shells/claude-unrestricted"

  run nix flake lock
  nix develop --command claude --version
  run nix develop --command true

  assert_success
  assert_output --partial 'Claude Code Development Shell (unrestricted)'
}
