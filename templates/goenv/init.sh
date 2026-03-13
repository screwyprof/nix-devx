#!/usr/bin/env bash
set -euo pipefail

# Initialize a new Go project from the goenv template.
# Usage: ./init.sh github.com/user/myproject

if [ $# -ne 1 ]; then
  echo "Usage: $0 <module-path>"
  echo "Example: $0 github.com/screwyprof/awesome"
  exit 1
fi

MODULE="$1"
BINARY="$(basename "$MODULE")"

echo "Initializing project:"
echo "  Module: $MODULE"
echo "  Binary: $BINARY"
echo ""

# Update go.mod module path
sed -i "s|^module hello|module $MODULE|" go.mod

# Update .golangci.yml (module path for import grouping)
sed -i "s|prefix(hello)|prefix($MODULE)|" .golangci.yml
sed -i "s|module-path: hello|module-path: $MODULE|" .golangci.yml
sed -i "s|        - hello|        - $MODULE|" .golangci.yml

# Update package.nix (binary name)
sed -i "s|pname = \"hello\"|pname = \"$BINARY\"|" package.nix
sed -i "s|mainProgram = \"hello\"|mainProgram = \"$BINARY\"|" package.nix

echo "Done! Next steps:"
echo "  1. git init && git add -A"
echo "  2. cp .envrc.example .envrc && direnv allow"
echo "  3. make help"
