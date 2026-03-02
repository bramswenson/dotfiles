# shellcheck shell=bash
# GPG agent configuration

# Kill ssh-agent in gnome-keyring
export GSM_SKIP_SSH_AGENT_WORKAROUND="true"

# Only set GPG_TTY when in an interactive shell with a TTY
if [[ $- == *i* ]] && [ -t 0 ]; then
  GPG_TTY=$(tty)
  export GPG_TTY
fi

# Set SSH to use gpg-agent
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  export SSH_AUTH_SOCK
fi
