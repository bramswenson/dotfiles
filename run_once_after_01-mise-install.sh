#!/usr/bin/env bash
set -euo pipefail

if ! command -v mise &>/dev/null; then
  echo "mise not found, skipping mise install"
  exit 0
fi

echo "Running mise install..."
mise install --yes
