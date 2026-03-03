# shellcheck shell=bash
# Prompt and toolchain activation

# Initialize starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

# Activate mise (runtime version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

# Activate direnv (per-directory environment)
if command -v direnv &>/dev/null; then
  eval "$(direnv hook bash)"
fi
