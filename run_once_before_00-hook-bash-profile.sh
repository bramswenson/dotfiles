#!/usr/bin/env bash
set -euo pipefail

BASH_PROFILE="${HOME}/.bash_profile"
HOOK='[ -f "${HOME}/.bashrc" ] && source "${HOME}/.bashrc"'

if [ -f "${BASH_PROFILE}" ]; then
  if ! grep -qF '.bashrc' "${BASH_PROFILE}"; then
    echo "" >> "${BASH_PROFILE}"
    echo "# Source .bashrc for login shells" >> "${BASH_PROFILE}"
    echo "${HOOK}" >> "${BASH_PROFILE}"
    echo "Hooked ~/.bashrc into ~/.bash_profile"
  else
    echo "~/.bash_profile already sources ~/.bashrc"
  fi
else
  echo "# Source .bashrc for login shells" > "${BASH_PROFILE}"
  echo "${HOOK}" >> "${BASH_PROFILE}"
  echo "Created ~/.bash_profile with ~/.bashrc hook"
fi
