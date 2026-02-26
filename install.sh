#!/usr/bin/env bash
#
# Zsh ↔ Bash toggle for Debian / Raspberry Pi OS
#   z-on  → enable clean Zsh (left prompt only)
#   z-off → remove added Zsh block + switch current session to bash
#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
# Fixed & hardened version – February 2026
#
# Run as: sudo bash this-script.sh

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Error: This script must be run with sudo."
    echo "  Example: sudo bash ${0##*/}"
    exit 1
fi

echo "Installing / updating z-on and z-off commands..."
echo "   → Clean prompt:  Thu Feb 26 11:45 ➤  (one space after arrow)"
echo ""

mkdir -p /usr/local/bin || { echo "Failed to create /usr/local/bin"; exit 1; }

# ────────────────────────────────────────────────
# z-on script
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-on << 'END_ZON'
#!/usr/bin/env bash
set -euo pipefail

echo "Enabling clean Zsh configuration..."

# Install required packages if missing
if ! dpkg-query -W -f='${Status}' zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null | grep -q "ok installed"; then
    echo "→ Installing zsh + plugins..."
    DEBIAN_FRONTEND=noninteractive apt update -qq
    DEBIAN_FRONTEND=noninteractive apt install -yqq zsh zsh-syntax-highlighting zsh-autosuggestions
fi

# Backup .zshrc safely
if [ -f "${HOME}/.zshrc" ]; then
    backup_file="${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
    cp "${HOME}/.zshrc" "${backup_file}" || { echo "Backup failed"; exit 1; }
    echo "→ Backed up ~/.zshrc → $(basename "${backup_file}")"
fi

# Add settings only if the marker block is not already present
if ! grep -q "=== Zsh nice settings added by z-on ===" "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" << 'END_ZSHRC'

# === Zsh nice settings added by z-on ===
#     (remove this whole block with z-off)

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS

# Shell options
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS
unsetopt NOMATCH

# Prompt – clean left side only
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%T %F{green}➤ %f'

# Optional right prompt (uncomment if desired later)
# RPROMPT='%F{8}%n@%m %1~%f'
# setopt TRANSIENT_RPROMPT

# Aliases
alias apt='sudo apt'

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Plugins
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Smart up/down arrow history search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# === End of z-on nice settings ===
END_ZSHRC

    echo "→ Added clean Zsh settings to ~/.zshrc"
else
    echo "→ Nice settings already present — skipping append"
fi

# Change default shell to zsh (affects new terminals/sessions)
zsh_path=$(command -v zsh)
if [ -n "$zsh_path" ] && chsh -s "$zsh_path" 2>/dev/null; then
    echo "→ Default shell changed to zsh (logout/login or new terminal to apply)"
else
    echo "→ Warning: Could not change default shell with chsh"
    echo "   Try manually:   chsh -s \$(which zsh)"
fi

echo ""
echo "Zsh is ready!"
echo "  • Run 'source ~/.zshrc' or open a new terminal"
echo "  • Revert with: z-off"
echo ""

exec zsh -l
END_ZON

# ────────────────────────────────────────────────
# z-off script
# ────────────────────────────────────────────────
cat > /usr/local/bin/z-off << 'END_ZOFF'
#!/usr/bin/env bash
set -euo pipefail

echo "Removing Zsh additions and switching to bash..."

# Backup both files if they exist
[ -f "${HOME}/.zshrc" ] && cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
[ -f "${HOME}/.bashrc" ] && cp "${HOME}/.bashrc" "${HOME}/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"

# Remove the added block
sed -i '/=== Zsh nice settings added by z-on ===/,/=== End of z-on nice settings ===/d' "${HOME}/.zshrc" 2>/dev/null || true

# Clean stray exec zsh lines (old versions)
sed -i '/exec.*zsh/d' "${HOME}/.bashrc" 2>/dev/null || true

# Switch default shell back to bash
bash_path=$(command -v bash)
if [ -n "$bash_path" ] && chsh -s "$bash_path" 2>/dev/null; then
    echo "→ Default shell set back to bash (new terminals will use bash)"
else
    echo "→ Warning: chsh failed"
    echo "   Run manually: chsh -s \$(which bash)"
fi

echo ""
echo "Bash restored (only toggle additions removed)."
echo "• Your other customizations are preserved."

# Switch current session
echo ""
echo "Switching this terminal session to bash now..."
sleep 1.2
exec bash -l
END_ZOFF

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off || { echo "chmod failed"; exit 1; }

echo ""
echo "Installation complete!"
echo "Commands:"
echo "  z-on      → clean Zsh (nice left prompt)"
echo "  z-off     → remove additions + switch to bash now"
echo ""
