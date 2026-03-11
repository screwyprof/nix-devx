#!/usr/bin/env bash
# Update flake.lock files for all ad-hoc shells
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHELLS_DIR="$SCRIPT_DIR/../shells"

for dir in "$SHELLS_DIR"/*/; do
  name=$(basename "$dir")
  echo "Updating $name..."
  (cd "$dir" && nix flake update)
done

echo "Done. Review changes with: git diff shells/*/flake.lock"
