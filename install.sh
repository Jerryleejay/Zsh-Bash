#!/bin/bash
#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
# Enhanced & safeguarded version 2026
#
# Perfect Zsh ↔ Bash toggle for Debian 12 / 13
#   z-on  → enable nice Zsh (plugins + settings appended non-destructively)
#   z-off → remove Zsh additions only (preserves your configs)
#
# Run once with: sudo bash this-file.sh

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Error: Please run with sudo"
    echo "  Example: sudo bash ${0##*/}"
    exit 1
fi

echo "Installing safer z-on / z-off toggle commands..."

mkdir -p /usr/local/bin
# Ensure /usr/local/bin is likely in PATH (most Debian systems have it)
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
    echo "Warning: /usr/local/bin not in PATH — add 'export PATH=/usr/local/bin:\$PATH' to your shell config if needed."
fi

# ────────────────────────────────────────────────
# z-on: Enable nice Zsh
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-on << 'INNER'
#!/usr/bin/env bash
set -euo pipefail

echo "Enabling nice Zsh setup..."

# Install missing packages quietly
if ! dpkg-query -W -f='${Status}' zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null | grep -Eq "ok installed"; then
    echo "Installing zsh + plugins..."
    DEBIAN_FRONTEND=noninteractive apt update -qq
    DEBIAN_FRONTEND=noninteractive apt install -yqq zsh zsh-syntax-highlighting zsh-autosuggestions
fi

# Backup .zshrc
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak."$(date +%Y%m%d-%H%M%S)"

# Append settings only if not already present
if ! grep -q "=== Zsh nice settings added by z-on ===" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'ZSHRC'

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
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%T %F{green}➤ %f'
RPROMPT='%F{red}%n%f@%F{white}%m%f %F{blue}%1~%f'

# Aliases & helpers ─────────────────────────────
alias apt='sudo apt'

# Aggressive full system update (use with caution!)
# update-system() {
#     sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt clean
# }

# Completions ───────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Plugins ───────────────────────────────────────
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Smart up/down arrows (history search from cursor position)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# === End of z-on nice settings ===
ZSHRC

    echo "→ Appended nice Zsh settings to ~/.zshrc (your existing config is preserved)"
else
    echo "→ Nice Zsh settings already present in ~/.zshrc — skipping"
fi

# Change default shell (logout/login required for full effect)
if chsh -s "$(command -v zsh)" 2>/dev/null; then
    echo "→ Default shell changed to zsh (logout & login to apply)"
else
    echo "→ Could not change shell automatically. Run manually:"
    echo "  chsh -s \$(command -v zsh)"
fi

echo ""
echo "Zsh is ready!"
echo "• Open a new terminal or run: source ~/.zshrc"
echo "• For permanent zsh default: logout/login after chsh"
echo "• To switch back later: just type 'z-off'"
exec zsh -l
INNER

# ────────────────────────────────────────────────
# z-off: Remove Zsh additions only
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-off << 'INNER'
#!/usr/bin/env bash
set -euo pipefail

echo "Disabling Zsh additions..."

# Backup .zshrc and .bashrc before changes
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak."$(date +%Y%m%d-%H%M%S)"
[ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.bak."$(date +%Y%m%d-%H%M%S)"

# Remove z-on appended block from .zshrc
sed -i '/=== Zsh nice settings added by z-on ===/,/=== End of z-on nice settings ===/d' ~/.zshrc 2>/dev/null || true

# Remove any stray old auto-switch lines from .bashrc (if present from older version)
sed -i '/# Auto-switch to Zsh (added by z-on)/,/zsh -l/d' ~/.bashrc 2>/dev/null || true

# Change default shell back to bash
if chsh -s "$(command -v bash)" 2>/dev/null; then
    echo "→ Default shell changed back to bash (logout & login to apply)"
else
    echo "→ Could not change shell automatically. Run manually:"
    echo "  chsh -s \$(command -v bash)"
fi

echo ""
echo "Bash restored (only toggle additions removed)."
echo "• Your custom .zshrc / .bashrc changes are preserved."
echo "• Open a new terminal or run: exec bash -l"
INNER

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo ""
echo "Perfect toggle installed successfully!"
echo ""
echo "Usage:"
echo "  z-on      → Append nice Zsh + plugins (non-destructive)"
echo "  z-off     → Remove only the z-on additions"
echo ""
echo "Permanent default shell:"
echo "  chsh -s /bin/zsh    (or /bin/bash) — then logout/login"
echo ""
echo "Enjoy your clean, toggleable setup! 🚀"
