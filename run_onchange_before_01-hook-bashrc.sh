#!/usr/bin/env bash
# Ensure ~/.bashrc sources ~/.bramrc — runs on content change
set -euo pipefail

BASHRC="${HOME}/.bashrc"
HOOK='[ -f "${HOME}/.bramrc" ] && source "${HOME}/.bramrc"'

if [ -f "${BASHRC}" ]; then
  if ! grep -qF '.bramrc' "${BASHRC}"; then
    echo "" >> "${BASHRC}"
    echo "# Load dotfiles configuration" >> "${BASHRC}"
    echo "${HOOK}" >> "${BASHRC}"
    echo "Hooked ~/.bramrc into ~/.bashrc"
  else
    echo "~/.bashrc already sources ~/.bramrc"
  fi
else
  echo "# Load dotfiles configuration" > "${BASHRC}"
  echo "${HOOK}" >> "${BASHRC}"
  echo "Created ~/.bashrc with ~/.bramrc hook"
fi
