# shellcheck shell=bash
# Shell aliases

# Linux xdg-open alias
if command -v xdg-open &>/dev/null; then
  alias open="xdg-open"
fi

# Lock screen
if command -v xscreensaver-command &>/dev/null; then
  alias lock="xscreensaver-command --lock &> /dev/null"
fi

# Git shortcuts (supplement gitconfig aliases)
alias gs="git status"
alias gd="git diff"
alias gdc="git diff --cached"
alias gl="git log --graph --decorate --pretty=oneline --abbrev-commit"
