#!/usr/bin/env sh

# Use absolute paths or ensure we are in the right spot
CDIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$CDIR/.." && pwd)"

# Copy templates only if they don't exist
if [ ! -f "$ROOT/.devcontainer/docker-compose.override.yml" ]; then
    cp "$ROOT/.devcontainer/docker-compose.override.template.yml" "$ROOT/.devcontainer/docker-compose.override.yml"
fi

# Ensure the .envrc for the container is ready
if [ ! -f "$ROOT/.devcontainer/.envrc.container" ]; then
    cp "$ROOT/.devcontainer/.envrc.template" "$ROOT/.devcontainer/.envrc.container"
fi