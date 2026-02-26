#!/usr/bin/env bash
# =============================================================================
# Zsh ↔ Bash toggle script for Debian / Raspberry Pi OS
#   z-on  → enable clean Zsh with nice left prompt
#   z-off → remove added Zsh block + switch current session to bash
#
# Fixed version: proper $HOME handling (no tilde-in-quotes bug)
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
# Last fixed: February 2026
#
# Recommended: sudo bash this-script.sh
# =============================================================================

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Error: This script must be run with sudo."
    echo "Example: sudo bash ${0##*/}"
    exit 1
fi

echo "Installing / updating z-on and z-off commands..."
echo "   → Clean prompt: Thu Feb 26 12:05 ➤  (one space after arrow)"
echo ""

mkdir -p /usr/local/bin || { echo "Failed to create /usr/local/bin"; exit 1; }

# =============================================================================
# Create z-on command
# =============================================================================
cat > /usr/local/bin/z-on << 'END_ZON'
#!/usr/bin/env bash
set -euo pipefail

echo "Enabling clean Zsh configuration..."

# Install zsh + plugins if not present
if ! dpkg-query -W -f='${Status}' zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null | grep -q "ok installed"; then
    echo "→ Installing zsh and plugins..."
    DEBIAN_FRONTEND=noninteractive apt update -qq
    DEBIAN_FRONTEND=noninteractive apt install -yqq zsh zsh-syntax-highlighting zsh-autosuggestions
fi

# Backup .zshrc using $HOME (safe in all contexts)
if [ -f "${HOME}/.zshrc" ]; then
    backup="${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
    if cp "${HOME}/.zshrc" "${backup}"; then
        echo "→ Backed up ~/.zshrc to $(basename "${backup}")"
    else
        echo "Error: Could not create backup – check disk space / permissions"
        exit 1
    fi
fi

# Append nice settings only if the block doesn't already exist
if ! grep -q "=== Zsh nice settings added by z-on ===" "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" << 'END_ZSHRC'

# === Zsh nice settings added by z-on ===
#     (remove this whole block with z-off if desired)

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS

# Shell options
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS
unsetopt NOMATCH

# Prompt – clean left prompt only
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%T %F{green}➤ %f'

# Optional: subtle right prompt (uncomment if you want it later)
# RPROMPT='%F{8}%n@%m %1~%f'
# setopt TRANSIENT_RPROMPT

# Useful aliases
alias apt='sudo apt'

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Plugins
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Smart up/down arrow for history search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# === End of z-on nice settings ===
END_ZSHRC

    echo "→ Added clean Zsh settings to ~/.zshrc"
else
    echo "→ Nice settings already present – skipping append"
fi

# Change default login shell to zsh
zsh_path=$(command -v zsh)
if [ -n "$zsh_path" ] && chsh -s "$zsh_path" 2>/dev/null; then
    echo "→ Default shell set to zsh (affects new terminals / relogin)"
else
    echo "→ Warning: chsh failed – you can run manually:"
    echo "   chsh -s \$(which zsh)"
fi

echo ""
echo "Zsh is ready!"
echo "  • Run 'source ~/.zshrc' or open a new terminal to see it"
echo "  • To revert: type 'z-off'"
echo ""

exec zsh -l
END_ZON

# =============================================================================
# Create z-off command
# =============================================================================
cat > /usr/local/bin/z-off << 'END_ZOFF'
#!/usr/bin/env bash
set -euo pipefail

echo "Removing Zsh additions and switching to bash..."

# Backup both rc files if they exist
[ -f "${HOME}/.zshrc" ] && cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
[ -f "${HOME}/.bashrc" ] && cp "${HOME}/.bashrc" "${HOME}/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"

# Remove the added z-on block
sed -i '/=== Zsh nice settings added by z-on ===/,/=== End of z-on nice settings ===/d' "${HOME}/.zshrc" 2>/dev/null || true

# Remove any stray exec zsh lines from .bashrc (old versions)
sed -i '/exec.*zsh/d' "${HOME}/.bashrc" 2>/dev/null || true

# Switch default shell back to bash
bash_path=$(command -v bash)
if [ -n "$bash_path" ] && chsh -s "$bash_path" 2>/dev/null; then
    echo "→ Default shell set back to bash (new terminals will use bash)"
else
    echo "→ Warning: chsh failed – run manually:"
    echo "   chsh -s \$(which bash)"
fi

echo ""
echo "Bash restored (only the toggle additions were removed)."
echo "Your other customizations are preserved."

echo ""
echo "Switching this terminal session to bash now..."
sleep 1.2
exec bash -l
END_ZOFF

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo ""
echo "Done! Commands installed:"
echo "  z-on     → switch to clean Zsh"
echo "  z-off    → remove additions + switch current session to bash"
echo ""
echo "If you're on Raspberry Pi and see Wi-Fi country warnings:"
echo "  sudo raspi-config → Localisation Options → WLAN Country"
echo ""
