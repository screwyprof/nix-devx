#!/usr/bin/env sh

# Ensure we're working from the project root
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Copy template as starting point for override
if [ ! -f "$ROOT/.devcontainer/docker-compose.override.yml" ]; then
    cp "$ROOT/.devcontainer/docker-compose.override.template.yml" "$ROOT/.devcontainer/docker-compose.override.yml"
fi

# Ensure the .envrc for the container is ready
if [ ! -f "$ROOT/.devcontainer/.envrc" ]; then
    cp "$ROOT/.devcontainer/.envrc.template" "$ROOT/.devcontainer/.envrc"
fi