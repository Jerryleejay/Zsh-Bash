#!/bin/bash
#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
#
# Zsh ↔ Bash toggle for Debian 12 / 13
# Creates: z-on  → nice Zsh with plugins
#          z-off → restore normal Bash
#
# Run with: sudo bash this-file.sh

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Please run with sudo"
    echo "Example: sudo bash install-zsh-toggle.sh"
    exit 1
fi

echo "Creating z-on and z-off commands..."

# ───────────────────────────────
# Create z-on script
# ───────────────────────────────
cat > /usr/local/bin/z-on << 'INNER'
#!/usr/bin/env bash
set -euo pipefail

echo "Setting up nice Zsh..."

# Install packages only if missing
if ! dpkg-query -W -f='${Status}' zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null | grep -q "ok installed"; then
    apt update
    apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions
fi

# Backup old .zshrc if it exists
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d-%H%M%S)

# Write good .zshrc
cat > ~/.zshrc << 'ZSHRC'
# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE

# Nice options
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS
unsetopt NOMATCH

# Prompt
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%T %F{green}➤ %f'
RPROMPT='%F{red}%n%f@%F{white}%m%f %F{blue}%1~%f'

# Aliases & helpers
alias apt='sudo apt'

update-system() {
    sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt clean
}

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Plugins
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Smart arrows
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
ZSHRC

# Auto-start zsh from bash if possible (only add once)
if ! grep -q "exec.*zsh" ~/.bashrc 2>/dev/null; then
    echo >> ~/.bashrc
    echo "# Auto-switch to Zsh (added by z-on)" >> ~/.bashrc
    echo "if [[ -t 1 && -x \$(command -v zsh) ]]; then exec zsh -l; fi" >> ~/.bashrc
fi

echo "Zsh ready."
chsh -s "$(which zsh)" 2>/dev/null || echo "Run 'chsh -s \$(which zsh)' yourself if needed"
exec zsh -l
INNER

# ───────────────────────────────
# Create z-off script
# ───────────────────────────────
cat > /usr/local/bin/z-off << 'INNER'
#!/usr/bin/env bash
set -euo pipefail

echo "Restoring normal Bash..."

# Backup current .bashrc
[ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.bak.$(date +%Y%m%d-%H%M%S)

# Restore clean version from Debian default
if [ -f /etc/skel/.bashrc ]; then
    cp /etc/skel/.bashrc ~/.bashrc
else
    echo "# Minimal .bashrc restored by z-off" > ~/.bashrc
fi

# Remove auto-switch lines
sed -i '/exec.*zsh/d' ~/.bashrc
sed -i '/zsh -l/d' ~/.bashrc 2>/dev/null || true

chsh -s "$(which bash)" 2>/dev/null || echo "Run 'chsh -s \$(which bash)' yourself if needed"

echo "Bash restored."
exec bash -l
INNER

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo ""
echo "Done!"
echo "Now type:"
echo "  z-on     → switch to nice Zsh"
echo "  z-off    → go back to normal Bash"
echo ""
