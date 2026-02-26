#!/bin/bash
#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
# Final working version – February 2026
#
# Zsh ↔ Bash toggle for Debian 12 / 13 / Raspberry Pi OS
#   z-on  → enable nice Zsh (left prompt only)
#   z-off → remove only the added Zsh sections + auto-switch current session to bash
#
# Run once with: sudo bash this-file.sh

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Error: Please run with sudo"
    echo "  Example: sudo bash ${0##*/}"
    exit 1
fi

echo "Installing fixed z-on / z-off commands..."

mkdir -p /usr/local/bin

# ────────────────────────────────────────────────
# z-on: Enable nice Zsh (left prompt only)
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-on << 'INNER'
#!/usr/bin/env bash
set -euo pipefail

echo "Enabling nice Zsh setup (left prompt only)..."

# Install missing packages quietly
if ! dpkg-query -W -f='${Status}' zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null | grep -Eq "ok installed"; then
    echo "Installing zsh + plugins..."
    DEBIAN_FRONTEND=noninteractive apt update -qq
    DEBIAN_FRONTEND=noninteractive apt install -yqq zsh zsh-syntax-highlighting zsh-autosuggestions
fi

# Backup .zshrc
if [ -f "${HOME}/.zshrc" ]; then
    backup_file="${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
    cp "${HOME}/.zshrc" "${backup_file}" || {
        echo "Error: Could not create backup of .zshrc"
        exit 1
    }
fi

# Append settings only if the block doesn't exist yet
if ! grep -q "=== Zsh nice settings added by z-on ===" "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" << 'ZSHRC'

# === Zsh nice settings added by z-on ===
#     (remove this whole block with z-off if desired)

# History ───────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS

# Shell options ─────────────────────────────────
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS
unsetopt NOMATCH

# Prompt ────────────────────────────────────────
# Clean left prompt only (no right-side clutter)
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%T %F{green}➤ %f '

# If you ever want a subtle right prompt, uncomment and customize:
# RPROMPT='%F{8}%n@%m %1~%f'          # dim gray user@host dir on right
# or
# setopt TRANSIENT_RPROMPT             # hide right prompt while typing

# Aliases & helpers ─────────────────────────────
alias apt='sudo apt'

# Aggressive full system update (uncomment if you want it)
# update-system() {
#     sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt clean
# }

# Completions ───────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Plugins ───────────────────────────────────────
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Smart up/down arrows ──────────────────────────
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# === End of z-on nice settings ===
ZSHRC

    echo "→ Appended nice Zsh settings to ~/.zshrc"
else
    echo "→ Nice Zsh settings already present — skipping append"
fi

# Change default shell
if chsh -s "$(command -v zsh)" 2>/dev/null; then
    echo "→ Default shell set to zsh (logout & login or new terminal to apply)"
else
    echo "→ Could not change shell. Run manually: chsh -s \$(command -v zsh)"
fi

echo ""
echo "Zsh ready!"
echo "• Run 'source ~/.zshrc' or open new terminal"
echo "• To go back: type 'z-off'"
exec zsh -l
INNER

# ────────────────────────────────────────────────
# z-off: Remove added sections + auto-switch to bash
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-off << 'INNER'
#!/usr/bin/env bash
set -euo pipefail

echo "Removing Zsh additions..."

# Backup before changes
[ -f "${HOME}/.zshrc" ] && cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
[ -f "${HOME}/.bashrc" ] && cp "${HOME}/.bashrc" "${HOME}/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"

# Remove the entire added block
sed -i '/=== Zsh nice settings added by z-on ===/,/=== End of z-on nice settings ===/d' "${HOME}/.zshrc" 2>/dev/null || true

# Clean up stray old lines
sed -i '/exec.*zsh/d' "${HOME}/.bashrc" 2>/dev/null || true

# Switch default shell back to bash
if chsh -s "$(command -v bash)" 2>/dev/null; then
    echo "→ Default shell set back to bash"
else
    echo "→ Could not change shell. Run manually: chsh -s \$(command -v bash)"
fi

echo ""
echo "Bash restored (only toggle additions removed)."
echo "• Your other customizations preserved."

echo ""
echo "Switching this terminal session to bash now..."
sleep 1.2
# Suppress rfkill / Wi-Fi blocked message on Raspberry Pi
exec bash -l 2>/dev/null
INNER

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo ""
