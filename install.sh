#!/bin/bash
#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
# Enhanced, fixed & cleaned version 2026
#
# Zsh ↔ Bash toggle script for Debian / Raspberry Pi OS
#   z-on  → enable clean Zsh (left prompt only, no extra space)
#   z-off → remove added Zsh sections + switch current session to bash
#
# Recommended run: sudo bash this-script.sh

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Error: This script must be run with sudo."
    echo "Example: sudo bash ${0##*/}"
    exit 1
fi

echo "Installing / updating z-on and z-off commands..."
echo "   → clean left prompt: date time ➤ [one space then cursor]"
echo ""

mkdir -p /usr/local/bin

# ────────────────────────────────────────────────
# z-on: Enable clean Zsh setup
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-on << 'INNER_EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Enabling clean Zsh configuration..."

# Install zsh + popular plugins if missing
if ! dpkg-query -W -f='${Status}' zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null | grep -q "ok installed"; then
    echo "→ Installing zsh and plugins..."
    DEBIAN_FRONTEND=noninteractive apt update -qq
    DEBIAN_FRONTEND=noninteractive apt install -yqq zsh zsh-syntax-highlighting zsh-autosuggestions
fi

# Backup current .zshrc (with timestamp)
if [ -f ~/.zshrc ]; then
    backup="~/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
    cp ~/.zshrc "$backup"
    echo "→ Backed up ~/.zshrc → $backup"
fi

# Append our nice settings only if not already present
if ! grep -q "=== Zsh nice settings added by z-on ===" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'ZSHRC_EOF'

# === Zsh nice settings added by z-on ===
#     (remove this whole block with z-off if desired)

# ────────────────────────────────────────────────
# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS

# ────────────────────────────────────────────────
# Shell behavior
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS
unsetopt NOMATCH

# ────────────────────────────────────────────────
# Prompt (clean left side only)
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%T %F{green}➤ %f'

# Optional right prompt (uncomment if wanted)
# RPROMPT='%F{8}%n@%m %1~%f'
# setopt TRANSIENT_RPROMPT

# ────────────────────────────────────────────────
# Aliases
alias apt='sudo apt'

# Optional full-system update function (uncomment to enable)
# update-system() {
#     sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt clean
# }

# ────────────────────────────────────────────────
# Completions & plugins
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Smart history search with up/down arrows
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# === End of z-on nice settings ===
ZSHRC_EOF

    echo "→ Added clean Zsh settings to ~/.zshrc"
else
    echo "→ Zsh nice settings already present — skipping append"
fi

# Change default shell to zsh (affects new sessions)
if chsh -s "$(command -v zsh)" 2>/dev/null; then
    echo "→ Default shell changed to zsh (new terminals / login will use it)"
else
    echo "→ Warning: Could not change default shell (chsh failed)"
    echo "   You can do it manually:   chsh -s \$(which zsh)"
fi

echo ""
echo "Zsh is ready!"
echo "  • Run 'source ~/.zshrc' or open a new terminal to see the clean prompt"
echo "  • To revert: type 'z-off'"
echo ""

exec zsh -l
INNER_EOF

# ────────────────────────────────────────────────
# z-off: Remove additions and switch back to bash
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-off << 'INNER_EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Removing Zsh additions and switching to bash..."

# Backup .zshrc and .bashrc
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak."$(date +%Y%m%d-%H%M%S)"
[ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.bak."$(date +%Y%m%d-%H%M%S)"

# Remove our added block from .zshrc
sed -i '/=== Zsh nice settings added by z-on ===/,/=== End of z-on nice settings ===/d' ~/.zshrc 2>/dev/null || true

# Clean up any old stray exec zsh lines in .bashrc
sed -i '/exec.*zsh/d' ~/.bashrc 2>/dev/null || true

# Switch default shell back to bash
if chsh -s "$(command -v bash)" 2>/dev/null; then
    echo "→ Default shell set back to bash (new terminals will use bash)"
else
    echo "→ Warning: Could not change default shell"
    echo "   Run manually: chsh -s \$(which bash)"
fi

echo "Bash restored (Zsh additions removed — custom configs preserved)."

# Switch current session to bash
echo ""
echo "Switching this session to bash now..."
sleep 1

# If on Raspberry Pi, suppress rfkill message for cleaner output
if [ -f /etc/os-release ] && grep -qi "Raspbian\|Raspberry Pi" /etc/os-release; then
    # Minimal way to avoid rfkill spam on login shells (temporary for this exec)
    exec bash -l 2>/dev/null
else
    exec bash -l
fi
INNER_EOF

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo "Done!"
echo ""
echo "Commands installed:"
echo "  z-on     → switch to clean Zsh (left prompt only)"
echo "  z-off    → remove additions + switch current session to bash"
echo ""
echo "Note: Permanent shell change affects new terminals only."
echo "      Use 'chsh -s /bin/zsh' or 'chsh -s /bin/bash' for that."
echo ""
echo "If you're on Raspberry Pi and see Wi-Fi country warnings:"
echo "  → Run 'sudo raspi-config' → Localisation Options → WLAN Country"
echo ""
