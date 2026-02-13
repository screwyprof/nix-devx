#!/usr/bin/env bash
set -euo pipefail

# Copy templates if targets don't exist
[ ! -f .devcontainer/docker-compose.override.yml ] && \
  cp .devcontainer/docker-compose.override.template.yml .devcontainer/docker-compose.override.yml

[ ! -f .devcontainer/.envrc ] && \
  cp .devcontainer/.envrc.template .devcontainer/.envrc
