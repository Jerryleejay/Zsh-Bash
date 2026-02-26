#!/bin/bash
#
# zsh-bash-toggle.sh
# =============================================================================
# Zsh ↔ Bash toggle script for Debian / Raspberry Pi OS
#
#   z-on   → enable nice Zsh (clean left prompt only)
#   z-off  → remove added Zsh sections + switch current session to bash
#
# Features:
# - Clean prompt: Thu Feb 26 11:45 ➤ 
# - Backups use ${HOME} (works correctly as root)
# - Suppresses Raspberry Pi rfkill/Wi-Fi blocked message during switch
#
# Author:     Terry L. Claiborne, KC3KMV
# Copyright:  (C) 2026 Terry L. Claiborne, KC3KMV
# Version:    Final fixed – February 2026
#
# Installation:
#   sudo bash zsh-bash-toggle.sh
#
# Usage:
#   z-on    # switch to Zsh
#   z-off   # switch back to Bash (in current session)
# =============================================================================

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Error: This script must be run with sudo."
    echo "  Example: sudo bash ${0##*/}"
    exit 1
fi

echo "Installing / updating z-on and z-off commands..."
echo "   → Clean left prompt: Thu Feb 26 11:45 ➤  (one space after arrow)"
echo ""

mkdir -p /usr/local/bin || { echo "Failed to create /usr/local/bin"; exit 1; }

# =============================================================================
# z-on – Enable nice Zsh
# =============================================================================
cat > /usr/local/bin/z-on << 'END_ZON'
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

# Append settings only if block doesn't exist
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
END_ZON

# =============================================================================
# z-off – Remove additions and switch to bash (with rfkill suppression)
# =============================================================================
cat > /usr/local/bin/z-off << 'END_ZOFF'
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
# Suppress Raspberry Pi rfkill / Wi-Fi blocked message
exec bash -l 2>/dev/null
END_ZOFF

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo ""
echo "Installation complete!"
echo "Commands:"
echo "  z-on      → nice Zsh (left prompt only)"
echo "  z-off     → remove additions + switch to bash now (no rfkill spam)"
echo ""
echo "Note: If you see a syntax error in /root/.bashrc after switching,"
echo "      edit /root/.bashrc and fix the if/fi mismatch around line 117."
echo ""
