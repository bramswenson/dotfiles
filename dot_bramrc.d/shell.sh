# shellcheck shell=bash
# Interactive shell settings — history, completions, keybindings

# Bash completion
if [ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
  . /opt/homebrew/etc/profile.d/bash_completion.sh
elif [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Interactive-only settings
if [[ $- == *i* ]]; then
  bind "set bell-style visible"
  bind "set completion-ignore-case on"
  bind "set show-all-if-ambiguous on"
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'

  # Allow ctrl-S for history navigation (with ctrl-R)
  stty -ixon 2>/dev/null
fi

# History
export HISTFILESIZE=100000
export HISTSIZE=5000
export HISTCONTROL=erasedups:ignoredups:ignorespace
shopt -s histappend
PROMPT_COMMAND='history -a'

# Shell options
shopt -s checkwinsize
shopt -s globstar 2>/dev/null
