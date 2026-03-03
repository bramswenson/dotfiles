#!/usr/bin/env bash
set -euo pipefail

if ! command -v vim &>/dev/null; then
  echo "vim not found, skipping plugin install"
  exit 0
fi

# Install vim-plug if not present
PLUG_VIM="${HOME}/.vim/autoload/plug.vim"
if [ ! -f "${PLUG_VIM}" ]; then
  echo "Installing vim-plug..."
  curl -fLo "${PLUG_VIM}" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "Installing vim plugins..."
vim +'PlugInstall --sync' +qa
