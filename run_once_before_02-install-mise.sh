#!/usr/bin/env bash
set -euo pipefail

if command -v mise &>/dev/null; then
  echo "mise already installed"
  exit 0
fi

echo "Installing mise..."
curl https://mise.run | sh
