# dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/), development
tool versions managed by [mise](https://mise.jdx.dev/), and git hooks enforced
by [hk](https://hk.jdx.dev/). Credentials prefer dynamic CLI auth flows
(`gh auth token`, `aws sso login`, etc.) over stored secrets.
[SOPS](https://getsops.io/) + GPG (YubiKey-backed) is available for any
secrets that don't have a CLI auth flow.

Supports **Linux** (Ubuntu, Fedora, RHEL) and **macOS** (Apple Silicon + Intel).

## Quick Start

### New Machine (local)

```bash
# 1. Insert YubiKey and verify GPG agent can see it
gpg --card-status

# 2. Install chezmoi and apply dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply bramswenson/dotfiles

# 3. chezmoi will prompt for machine-specific config (hostname, email, work context)
#    Core configs deploy without secrets. If gpg-agent is working, secrets
#    also decrypt in the same pass.
```

### New Machine (remote)

From your local machine (with YubiKey inserted):

```bash
# One command — handles gpg-agent forwarding and chezmoi install
bootstrap-remote <hostname>
```

This script SSH's to the remote host with gpg-agent forwarding configured
inline, then runs `chezmoi init --apply`. Core configs (GPG, SSH, shell)
always deploy successfully without secrets. If the forwarding is working,
secrets also decrypt in the same pass. Either way, after this the remote
host's SSH config has `RemoteForward` baked in, so future SSH sessions
forward gpg-agent automatically.

### Existing Machine (update)

```bash
chezmoi update
```

## Prerequisites

These tools must be installed before or during bootstrap. The `run_once_before_*`
scripts handle installing mise automatically on first `chezmoi apply`.

| Tool | Purpose | Install |
|------|---------|---------|
| [chezmoi](https://www.chezmoi.io/) | Dotfile management | `sh -c "$(curl -fsLS get.chezmoi.io)"` |
| [GnuPG](https://gnupg.org/) | Encryption, signing, SSH agent | OS package (Tier 3) |
| YubiKey | Hardware-backed GPG private keys | Physical device |
| [SOPS](https://getsops.io/) | Structured secret encryption | Official installer (Tier 2) |
| [mise](https://mise.jdx.dev/) | Dev tool version manager | Auto-installed by chezmoi script |

## Package Installation Strategy

Packages are installed in three tiers, each with a clear purpose:

### Tier 1: mise (multi-version tools)

Tools where you need different versions across projects. These are the **only**
tools managed by mise globally.

- node, python, ruby, go, java

Configured globally in `~/.config/mise/config.toml` (managed by chezmoi) and
per-project in each repo's `mise.toml`.

Rust is managed by `rustup` directly, not mise.

### Tier 2: Official install scripts

Development, security, and commonly-used tools installed via their own official
installers. These are kept as executable scripts in `~/.local/bin/install-*`.

- sops, starship, docker, kubectl, helm, k9s, gh, aws-cli,
  google-cloud-sdk, 1password, yubikey tools

chezmoi and mise are special cases — chezmoi is self-bootstrapping via
`get.chezmoi.io`, and mise is auto-installed by a chezmoi `run_once_before`
script. Both use their official installers but don't need `install-*` scripts.

On macOS, prefer official `.pkg` installers when available (e.g., AWS CLI ships
a `.pkg` and that should always be used over Homebrew).

### Tier 3: OS packages

System-level packages installed via the OS package manager through bootstrap
scripts.

- **Linux**: `apt` (Ubuntu/Debian) or `dnf` (Fedora/RHEL) via `bootstrap-ubuntu`,
  `bootstrap-fedora`, or `bootstrap-rhel`
- **macOS**: `brew bundle --global` via `~/.Brewfile`. Homebrew is the macOS
  equivalent of apt/dnf — it handles Tier 3 system-level packages only. Tools
  with official installers (Tier 2) are NOT in the Brewfile. The Brewfile
  contains a mix of `brew` formulas (CLI tools) and `cask` entries (GUI apps).
  Some tools don't install cleanly via Homebrew and are handled by
  `bootstrap-macos` directly.

Includes: build-essential, gcc, dev libs, git, git-lfs, gnupg2, tmux, vim,
neovim, curl, wget, jq, yq, ripgrep, fd, bat, fzf, htop, tree, direnv, GUI
apps (slack, discord, firefox, etc.), nerd fonts.

## Repository Structure

This is a [chezmoi source directory](https://www.chezmoi.io/reference/special-files-and-directories/). Files use chezmoi naming conventions to control how they're deployed to `$HOME`.

```
~/Code/bramswenson/dotfiles/
├── .chezmoi.toml.tmpl              # Machine-specific config template
├── .chezmoiignore                  # OS-specific file exclusions
├── .sops.yaml                      # SOPS encryption rules
├── .gitignore
├── README.md
├── hk.pkl                          # Git hooks (gitleaks + SOPS enforcement)
├── mise.toml                       # Repo-level tools (shellcheck, hk, gitleaks)
│
├── secrets.yaml                    # SOPS-encrypted secrets (GPG-backed)
├── public_keys/                    # GPG public keys for SOPS recipients
│
├── dot_bramrc                      # → ~/.bramrc (sources ~/.bramrc.d/*)
├── dot_inputrc                     # → ~/.inputrc
├── dot_vimrc                       # → ~/.vimrc
├── dot_tmux.conf                   # → ~/.tmux.conf
├── dot_gitconfig.tmpl              # → ~/.gitconfig (templated)
├── dot_gitignore_global            # → ~/.gitignore (global)
├── dot_abcde.conf                  # → ~/.abcde.conf
│
├── dot_bramrc.d/                   # → ~/.bramrc.d/ (modular shell config)
│   ├── aliases.sh                  #   General aliases and exports
│   ├── path.sh.tmpl                #   PATH construction (OS-aware)
│   ├── gpg.sh                      #   GPG agent / SSH agent setup
│   ├── murm.sh.tmpl                #   Murmuration work config
│   └── prompt.sh                   #   Starship prompt init
│
├── private_dot_gnupg/              # → ~/.gnupg/ (0700 permissions)
│   ├── gpg.conf                    #   GPG options
│   ├── gpg-agent.conf.tmpl         #   Agent config (OS-specific pinentry)
│   ├── scdaemon.conf               #   YubiKey smartcard config
│   └── sshcontrol                  #   SSH key grips
│
├── private_dot_ssh/                # → ~/.ssh/ (0700 permissions)
│   └── config.tmpl                 #   SSH config (global settings)
│
├── dot_config/
│   ├── starship.toml               # → ~/.config/starship.toml
│   └── private_mise/
│       └── config.toml             # → ~/.config/mise/config.toml
│
├── dot_local/
│   └── bin/                        # → ~/.local/bin/
│       ├── executable_skel         #   Script template pattern
│       ├── executable_bmux         #   Tmux session helper
│       ├── executable_bootstrap-ubuntu
│       ├── executable_bootstrap-fedora
│       ├── executable_bootstrap-rhel
│       ├── executable_bootstrap-macos
│       ├── executable_bootstrap-remote  # Bootstrap a remote host from local
│       ├── executable_install-*    #   Tier 2 install scripts
│       ├── executable_upgrade-*    #   OS upgrade helpers
│       └── executable_fix-*        #   Platform-specific fixes
│
├── dot_Brewfile                    # → ~/.Brewfile (macOS only)
│
├── run_once_before_01-install-mise.sh
├── run_once_before_02-hook-bashrc.sh        # Adds "[ -f ~/.bramrc ] && . ~/.bramrc" to ~/.bashrc
├── run_once_after_01-mise-install.sh
└── run_once_after_02-vim-plugins.sh
```

### Chezmoi naming conventions

| Prefix | Effect |
|--------|--------|
| `dot_` | Replaced with `.` in target path |
| `private_` | Target gets `0700`/`0600` permissions |
| `executable_` | Target gets executable bit set |
| `encrypted_` | File is encrypted via chezmoi (not used — we use SOPS instead) |
| `.tmpl` suffix | Processed as a Go template before deployment |
| `run_once_before_` | Script runs once before file deployment |
| `run_once_after_` | Script runs once after file deployment |

## Credentials and Secrets

### Dynamic credentials (preferred)

Most credentials are obtained dynamically via CLI tools that have their own
auth flows. This avoids storing secrets in files entirely — just authenticate
once per machine:

| Credential | How to get it | Auth setup |
|------------|--------------|------------|
| GitHub token | `gh auth token` | `gh auth login` |
| AWS credentials | `aws sso login` / `aws configure` | AWS SSO or IAM |
| Google Cloud | `gcloud auth login` | OAuth browser flow |
| Docker registry | `docker login` | Registry credentials |
| Kubernetes | `kubectl` via OIDC/SSO | Cluster-specific |

Shell configs use these dynamically:
```bash
export GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
```

### SOPS (for secrets without CLI auth flows)

For secrets that don't have a CLI auth flow (webhook URLs, static API tokens,
etc.), [SOPS](https://getsops.io/) encrypts them in `secrets.yaml` using GPG.
Private keys live on YubiKeys — no separate key files to manage.

**How it works:**

1. Secrets live in `secrets.yaml` in the repo root (starts empty, grows as needed)
2. SOPS encrypts the **values** while leaving keys in plaintext (diffs are readable)
3. `.sops.yaml` lists GPG key fingerprints that can decrypt the file
4. GPG public keys are stored in `public_keys/` in the repo
5. Decryption uses the GPG private key on your YubiKey via gpg-agent
6. On remote hosts, gpg-agent forwarding means `sops -d` just works
7. Chezmoi templates call `sops -d` to decrypt secrets at apply time

### Design principle: core configs never depend on secrets

GPG, SSH, shell, and editor configs deploy without decrypting any secrets.
Only "leaf" configs (work-specific `~/.bramrc.d/murm.sh`, etc.) may reference
SOPS secrets. This means `chezmoi apply` always succeeds for core functionality,
even if gpg-agent isn't available yet — solving the chicken-and-egg problem
on new machines.

### SOPS configuration (`.sops.yaml`)

```yaml
creation_rules:
  - pgp: D3B9C00B365DC5B752A6554A0630571A396BC2A7
```

SOPS uses GPG key fingerprints. Additional recipients (e.g., a backup YubiKey)
can be added as comma-separated fingerprints.

### Secret file structure

```yaml
# secrets.yaml (values are SOPS-encrypted, keys are plaintext)
# Only for secrets that DON'T have a CLI auth flow.
# GitHub → use `gh auth token`, AWS → use `aws sso login`, etc.
github_username: ENC[AES256_GCM,data:...,type:str]
```

### Using secrets in templates

```
{{- $secrets := output "sops" "-d" (joinPath .chezmoi.sourceDir "secrets.yaml") | fromYaml -}}
export SOME_SECRET="{{ $secrets.some_key }}"
```

For credentials with CLI auth flows, use dynamic lookups instead:
```bash
export GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
```

### Setting up a new machine

Works the same whether you're local or SSH'd in with gpg-agent forwarding:

```bash
# 1. Verify YubiKey / gpg-agent is working
gpg --card-status   # should show your card details

# 2. Import public keys from the repo (if not already in keyring)
gpg --import public_keys/*.gpg

# 3. chezmoi apply will now be able to decrypt secrets via gpg-agent
chezmoi apply
```

### Editing secrets

```bash
# Edit secrets in your $EDITOR (decrypts on open, re-encrypts on save)
# Requires YubiKey to be inserted (or gpg-agent forwarded)
sops secrets.yaml
```

### Adding a new YubiKey

When you initialize a new YubiKey (e.g., a backup key or a dedicated work
key), add its GPG public key as a SOPS recipient so it can decrypt secrets:

```bash
# 1. Export the new YubiKey's public key
gpg --export --armor new-key@example.com > public_keys/new_key.gpg

# 2. Add the fingerprint to .sops.yaml
# 3. Re-encrypt secrets with all YubiKeys as recipients:
sops updatekeys secrets.yaml

# 4. Commit and push
```

### Key management

- **Private keys**: live on YubiKeys only, never on disk
- **Public keys**: stored in `public_keys/` in this repo
- **Multiple YubiKeys**: personal + work (or backup) — each is a SOPS
  recipient, any of them can decrypt secrets
- **Any machine**: insert a YubiKey (or forward gpg-agent via SSH) and
  secrets just work

## GPG and SSH Setup

This repo uses GPG agent as the SSH agent, with a YubiKey for key storage.
GPG agent forwarding over SSH enables signing and authentication on remote
hosts.

### Architecture

```
┌─────────────────────────────────────┐
│ Local Machine                       │
│                                     │
│  YubiKey ──► scdaemon ──► gpg-agent │
│                             │       │
│                     SSH socket      │
│                     (SSH_AUTH_SOCK) │
│                             │       │
│                     Extra socket    │
│                     (for forwarding)│
└────────────────────────┬────────────┘
                         │ SSH RemoteForward
┌────────────────────────▼────────────┐
│ Remote Host                         │
│                                     │
│  Forwarded socket ──► gpg/ssh ops   │
└─────────────────────────────────────┘
```

### Cross-platform configuration

GPG and SSH configs are templated for OS differences:

**`gpg-agent.conf`** — pinentry program differs by OS:
- Linux: `/usr/bin/pinentry-gnome3`
- macOS: `/opt/homebrew/bin/pinentry-mac` (Apple Silicon) or `/usr/local/bin/pinentry-mac` (Intel)

**`gpg.sh`** (shell config) — SSH_AUTH_SOCK is set portably via `gpgconf --list-dirs agent-ssh-socket`, which works on both platforms.

**`scdaemon.conf`** — YubiKey config (`disable-ccid`, `pcsc-shared`) works identically on both platforms.

### GPG agent forwarding

SSH `RemoteForward` can be configured per-host to tunnel the local gpg-agent
extra socket to remote hosts, enabling GPG signing and SSH authentication
without the YubiKey being physically connected to the remote machine.

Remote hosts must have `StreamLocalBindUnlink yes` in their `sshd_config`.

### SSH hardening

The SSH config explicitly disables the deprecated `ssh-rsa` algorithm (SHA-1
based) for all hosts. Modern servers use `rsa-sha2-256`/`rsa-sha2-512` or
Ed25519 instead.

### Useful commands

```bash
# Restart gpg-agent (after sleep/wake or YubiKey issues)
gpgconf --kill gpg-agent && gpg-connect-agent /bye

# Check YubiKey status
gpg --card-status

# Update TTY for pinentry (after switching terminals)
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye

# List SSH keys from gpg-agent
ssh-add -L
```

## Shell Configuration

Bash is the primary shell. Rather than managing `~/.bashrc` directly (which
may be owned by the system, IT, or OS updates), this repo uses its own
namespace:

- **`~/.bramrc`** — entry point, sources all files in `~/.bramrc.d/`
- **`~/.bramrc.d/`** — modular shell configs

A one-time `run_once_` script appends a single line to `~/.bashrc`:

```bash
[ -f ~/.bramrc ] && . ~/.bramrc
```

This keeps `~/.bashrc` system-owned with minimal intrusion. All our shell
configuration lives in `~/.bramrc` and `~/.bramrc.d/`, fully isolated.

### `~/.bramrc.d/` modules

| File | Purpose |
|------|---------|
| `aliases.sh` | Command aliases (`open` → `xdg-open` on Linux), git shortcuts, editor/less exports |
| `path.sh.tmpl` | PATH construction (OS-aware, built via chezmoi template) |
| `gpg.sh` | GPG agent as SSH agent, GPG_TTY, SSH_AUTH_SOCK |
| `prompt.sh` | Starship prompt + mise activation |
| `murm.sh.tmpl` | Murmuration work config (conditional on work_context) |

### Work-specific configs

Work/contract-specific shell configuration uses the `~/.bramrc.d/` pattern.
Each engagement gets its own file:

- `murm.sh.tmpl` — Murmuration (current)
- Future: `acme.sh.tmpl`, etc.

These files are chezmoi templates (`.tmpl`) so they can use machine-specific
variables. They prefer dynamic CLI auth (`gh auth token`, etc.) and fall back
to SOPS secrets only for credentials without CLI auth flows. They're sourced
automatically by `~/.bramrc`:

```bash
for rc in ~/.bramrc.d/*; do
  [ -f "$rc" ] && . "$rc"
done
```

## Bootstrap Scripts

Bootstrap scripts handle full system setup for new machines. They install
Tier 3 (OS packages) and call Tier 2 (official install scripts) as needed.

### Linux

```bash
# Ubuntu/Debian
~/.local/bin/bootstrap-ubuntu

# Fedora
~/.local/bin/bootstrap-fedora

# RHEL
~/.local/bin/bootstrap-rhel
```

### macOS

```bash
~/.local/bin/bootstrap-macos
```

The macOS bootstrap:
1. Installs Xcode CLI tools
2. Installs Homebrew (if missing)
3. Runs `brew bundle --global` (installs from `~/.Brewfile`)
4. Runs Tier 2 install scripts for tools that need official `.pkg` installers
   or don't install cleanly via Homebrew
5. Adds Homebrew bash to `/etc/shells` and sets it as default shell

### Brewfile (macOS)

`~/.Brewfile` contains Tier 3 packages for macOS, organized as a mix of:
- `brew "..."` — CLI tools (formulas)
- `cask "..."` — GUI applications
- `tap "..."` — third-party Homebrew repositories

## mise Configuration

### Global tools (`~/.config/mise/config.toml`)

Tier 1 tools only — things where multiple versions are needed across projects:

```toml
[tools]
node = "lts"
python = "3.13"
ruby = "3.3"
go = "latest"
java = "21"
```

Rust is managed by `rustup` directly, not mise.

### Per-project tools

Each project repo can have its own `mise.toml` for project-specific versions:

```toml
[tools]
node = "20"
python = "3.11"
```

### Repo-level tools (`mise.toml` in this repo)

Tools used for working on the dotfiles repo itself (linting, hooks, secret scanning):

```toml
[tools]
gitleaks = "latest"
hk = "latest"
pkl = "latest"
shellcheck = "latest"
```

## Git Hooks (hk)

[hk](https://hk.jdx.dev/) manages git hooks via `hk.pkl` (Pkl configuration).
hk itself is installed via mise as a repo-level tool.

### Pre-commit hooks

1. **gitleaks** — scans for accidentally committed secrets
   (API keys, tokens, passwords, private keys)
2. **sops-check** — verifies `secrets.yaml` is properly SOPS-encrypted
   before allowing commits
3. **shellcheck** — lints shell scripts for common errors

### Setup

```bash
# Install hk hooks into the repo (after mise installs hk)
hk install
```

### Manual run

```bash
# Run all pre-commit checks manually
hk run pre-commit
```

## Machine-Specific Configuration

Chezmoi prompts for machine-specific values on `chezmoi init`. These are stored
in `~/.config/chezmoi/chezmoi.toml` (not committed to the repo).

### `.chezmoi.toml.tmpl`

```toml
[data]
name = {{ promptStringOnce . "name" "Full name" | quote }}
email = {{ promptStringOnce . "email" "Email address" | quote }}
work_context = {{ promptStringOnce . "work_context" "Work context (murm/none)" | quote }}
gpg_signing_key = {{ promptStringOnce . "gpg_signing_key" "GPG signing key (email or fingerprint)" | quote }}
```

### Using in templates

```
{{- if eq .work_context "murm" }}
# Murmuration-specific config
{{- end }}

[user]
    name = {{ .name }}
    email = {{ .email }}
    signingkey = {{ .gpg_signing_key }}
```

### `.chezmoiignore`

OS-specific files are excluded from deployment:

```
{{- if ne .chezmoi.os "darwin" }}
.Brewfile
.local/bin/bootstrap-macos
{{- end }}

{{- if ne .chezmoi.os "linux" }}
.local/bin/bootstrap-ubuntu
.local/bin/bootstrap-fedora
.local/bin/bootstrap-rhel
{{- end }}

{{- if ne .work_context "murm" }}
.bramrc.d/murm.sh
{{- end }}
```

## Common Operations

### Add a new dotfile

```bash
chezmoi add ~/.some-config
```

### Edit a managed file

```bash
chezmoi edit ~/.bramrc
# or edit directly in ~/Code/bramswenson/dotfiles/ and run:
chezmoi apply
```

### Preview changes before applying

```bash
chezmoi diff
```

### Update from remote

```bash
chezmoi update
```

### Add a new credential

First, check if the tool has a CLI auth flow (e.g., `gh auth login`,
`aws sso login`). If so, use dynamic lookups in shell configs:

```bash
export MY_TOKEN="$(some-tool auth token 2>/dev/null)"
```

If there's no CLI auth flow, add it to SOPS:

```bash
# Edit the secrets file (decrypts, opens editor, re-encrypts on save)
sops secrets.yaml

# Add a reference in the relevant template
# {{ $secrets.new_section.new_key }}
```

### Add a new work context

1. Create `dot_bramrc.d/<context>.sh.tmpl` with work-specific config
2. Add secrets under a new key in `secrets.yaml`
3. Gate deployment with `.chezmoiignore` or template conditionals on `.work_context`

### Add a new install script

1. Copy `executable_skel` as `dot_local/bin/executable_install-<tool>`
2. Add it to the relevant bootstrap script
3. Test: `chezmoi apply && install-<tool>`

## Migrating from rcm (`~/.dotfiles`)

Existing machines use rcm with symlinks from `~/.dotfiles`. This section covers
migrating to the chezmoi setup. The migration is safe — chezmoi overwrites
symlinks with real files, so rcm can be removed afterward.

### Before you start

1. Ensure your YubiKey works: `gpg --card-status`
2. Commit any local changes in `~/.dotfiles` you want to keep
3. Note any machine-specific customizations in `~/.dotfiles/bin/shell.env`

### Migration steps

```bash
# 1. Install chezmoi and apply the new dotfiles
#    chezmoi will overwrite rcm's symlinks with managed files
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply bramswenson/dotfiles

# 2. Verify the new shell works
#    Open a NEW terminal and confirm:
#    - prompt works (starship)
#    - git aliases work (gs, gd, etc.)
#    - GPG/SSH agent works (ssh-add -L)

# 3. Remove rcm symlinks and old dotfiles
rcdn  # removes all rcm-managed symlinks (leaves originals alone since chezmoi already wrote them)

# 4. Clean up
sudo apt remove rcm  # or: brew uninstall rcm
rm -rf ~/.dotfiles   # only after verifying everything works
rm -f ~/.rcrc
```

### What changes

| Old (rcm) | New (chezmoi) | Notes |
|-----------|---------------|-------|
| `~/.dotfiles/` | `~/.local/share/chezmoi/` | Source directory |
| `~/.bin/` | `~/.local/bin/` | Scripts location |
| `~/.bashrc` sources `shell.env` | `~/.bashrc` sources `~/.bramrc` | One-line hook added automatically |
| `~/.dotfiles/bin/shell.env` | `~/.bramrc.d/*.sh` | Monolithic → modular |
| `~/.dotfiles/bashrc` | Not managed | System-owned; chezmoi only injects the bramrc hook |
| rcm symlinks | Real files | chezmoi copies, not symlinks |
| Plaintext secrets in `shell.env` | Dynamic CLI auth / SOPS | See below |
| Volta, tfenv, nvm, pyenv | mise | Single tool manager |
| `rcup` | `chezmoi apply` | Apply changes |
| `lsrc` | `chezmoi managed` | List managed files |

### Scripts not carried forward

These old `~/.bin/` scripts were dropped from the new setup. Remove them
manually if still present after migration:

- `download-aws-cloudwatch-log-stream` — one-off utility
- `install-antigravity`, `install-circleci-cli`, `install-deno`, `install-devspace`,
  `install-garden`, `install-logcli`, `install-micromamba`, `install-modd`,
  `install-stripe-cli`, `install-tfenv`, `install-volta` — obsolete tools
- `print-jira-status`, `setup-dnsmasq`, `setup-nodejs`, `store-package-lists`,
  `update-dotfiles`, `update_dynamic_hostname` — Civiqs/legacy-specific
- `shell.env` — replaced by `~/.bramrc.d/` modules

### Secrets cleanup

The old `shell.env` contained plaintext secrets (API tokens, passwords). These
are **not** carried forward. After migration:

1. Rotate any tokens that were in `shell.env` (they were committed to git history)
2. Use CLI auth flows instead: `gh auth token`, `aws sso login`, etc.
3. For secrets without CLI auth, use SOPS: `sops secrets.yaml`

### Verifying the migration

After migrating, run the goss test suite to verify everything deployed correctly:

```bash
mise run test
```

## File Origins

This repo is a clean rebuild from a previous rcm-based dotfiles setup. The old
repo's git history contained plaintext secrets and is intentionally not carried
forward. Key configs were audited and migrated:

- Shell configs: refactored from monolithic `shell.env` into modular `~/.bramrc.d/`
- Secrets: plaintext tokens replaced with dynamic CLI auth (`gh auth token`, etc.);
  SOPS available for anything without a CLI auth flow
- Version managers: Volta, tfenv, nvm, pyenv consolidated into mise
- GPG/SSH: templated for cross-platform support (was Linux-only)
- Bootstrap scripts: improved with consistent error handling and shellcheck compliance
- Dropped: zsh/oh-my-zsh, ackrc (replaced by ripgrep), s3cfg, kodi, xscreensaver, runnel
