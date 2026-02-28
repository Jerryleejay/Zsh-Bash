#!/bin/bash
set -euo pipefail

#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Zsh Shell / Bash Shell Switcher - Debian 12 Debian 13
# Easily toggle between a custom Zsh setup and standard Bash.
# Universal version - works for any user and root

# ────────────────────────────────────────────────
# UNIVERSAL USER DETECTION
# ────────────────────────────────────────────────
# Works whether called as: user, sudo user, or root directly

if [ "$EUID" -eq 0 ]; then
    # Running as root via sudo or directly
    if [ -n "${SUDO_USER:-}" ]; then
        # Called with sudo
        REAL_USER="$SUDO_USER"
        REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    else
        # Running as root directly (no sudo)
        REAL_USER="root"
        REAL_HOME="/root"
    fi
else
    # Running as regular user (not sudo, not root)
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

echo "Detected user: $REAL_USER"
echo "Home directory: $REAL_HOME"

# For installation, we need root
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31m[ERROR]\033[0m Installation requires root. Please run: sudo bash $0"
    exit 1
fi

echo "Installing z-on and z-off to /usr/local/bin..."

# ────────────────────────────────────────────────
# Z-ON SCRIPT
# ────────────────────────────────────────────────
cat << 'ON_EOF' > /usr/local/bin/z-on
#!/bin/bash
set -euo pipefail

# UNIVERSAL USER DETECTION (same logic)
if [ "$EUID" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ]; then
        REAL_USER="$SUDO_USER"
        REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    else
        REAL_USER="root"
        REAL_HOME="/root"
    fi
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

echo "Target user: $REAL_USER ($REAL_HOME)"

# For package installation, we need root
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31m[ERROR]\033[0m z-on requires sudo. Please run: sudo z-on"
    exit 1
fi

echo "Updating packages..."
if ! apt update 2>&1 | grep -q "Reading"; then
    echo -e "\033[0;31m[ERROR]\033[0m Failed to update packages"
    exit 1
fi

echo "Installing zsh and plugins..."
if ! apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions > /dev/null 2>&1; then
    echo -e "\033[0;31m[ERROR]\033[0m Failed to install zsh packages"
    exit 1
fi

echo "Creating .zshrc at $REAL_HOME/.zshrc..."

cat << 'ZSHRC' > "$REAL_HOME/.zshrc"
# Zsh History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE
setopt AUTO_CD EXTENDED_GLOB
unsetopt NOMATCH

# Prompt Configuration
precmd() { print -rP "%F{red}%n %f- %F{white}%m %f[%F{blue}%1~%f]"; }
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%t %F{green}➤ %f'

# Aliases
alias apt='sudo apt'
update-system() { sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y; }

# Load plugins (safe check)
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History search with arrow keys
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
ZSHRC

# Fix ownership (critical for non-root users)
if ! chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.zshrc"; then
    echo -e "\033[0;31m[ERROR]\033[0m Failed to set .zshrc ownership"
    exit 1
fi

echo "Configuring .bashrc..."

# Create or update .bashrc for zsh launcher
if [ ! -f "$REAL_HOME/.bashrc" ]; then
    cat > "$REAL_HOME/.bashrc" << 'BASHRC'
# Default bash configuration
[ -z "$PS1" ] && return

# Start Zsh if available
if [[ -t 1 && -x $(command -v zsh) ]]; then
  exec zsh -l
fi
BASHRC
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.bashrc"
    echo "Created new .bashrc"
else
    # Don't add if already present
    if ! grep -q "exec zsh" "$REAL_HOME/.bashrc"; then
        echo -e "\n# Start Zsh\nif [[ -t 1 && -x \$(command -v zsh) ]]; then exec zsh -l; fi" >> "$REAL_HOME/.bashrc"
        echo "Added zsh launcher to .bashrc"
    else
        echo ".bashrc already configured for zsh"
    fi
fi

ZSH_PATH=$(command -v zsh)
echo "Changing default shell to $ZSH_PATH..."

if ! chsh -s "$ZSH_PATH" "$REAL_USER"; then
    echo -e "\033[0;31m[ERROR]\033[0m Failed to change shell for $REAL_USER"
    exit 1
fi

echo -e "\033[0;32m[SUCCESS]\033[0m Zsh installed and configured for $REAL_USER"
echo "Launching zsh..."

# Switch to the target user if not already that user
if [ "$USER" != "$REAL_USER" ]; then
    su - "$REAL_USER" -c "exec zsh -l"
else
    exec zsh -l
fi
ON_EOF

# ────────────────────────────────────────────────
# Z-OFF SCRIPT
# ────────────────────────────────────────────────
cat << 'OFF_EOF' > /usr/local/bin/z-off
#!/bin/bash
set -euo pipefail

# UNIVERSAL USER DETECTION (same logic)
if [ "$EUID" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ]; then
        REAL_USER="$SUDO_USER"
        REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    else
        REAL_USER="root"
        REAL_HOME="/root"
    fi
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

echo "Target user: $REAL_USER ($REAL_HOME)"

# For shell change, we need root
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31m[ERROR]\033[0m z-off requires sudo. Please run: sudo z-off"
    exit 1
fi

echo "Reverting to bash..."

# Ensure .bashrc exists
if [ ! -f "$REAL_HOME/.bashrc" ]; then
    echo "Creating default .bashrc..."
    cat > "$REAL_HOME/.bashrc" << 'DEFAULT_BASH'
# Default bash configuration
[ -z "$PS1" ] && return

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
alias apt='sudo apt'
DEFAULT_BASH
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.bashrc"
else
    # Remove only the zsh launcher lines
    if grep -q "# Start Zsh\|exec zsh" "$REAL_HOME/.bashrc"; then
        sed -i '/# Start Zsh/,/fi/d' "$REAL_HOME/.bashrc"
        # Also handle inline versions
        sed -i '/exec zsh/d' "$REAL_HOME/.bashrc"
        echo "Removed zsh launcher from .bashrc"
    else
        echo "Zsh launcher not found in .bashrc"
    fi
fi

BASH_PATH=$(command -v bash)
echo "Changing default shell to $BASH_PATH..."

if ! chsh -s "$BASH_PATH" "$REAL_USER"; then
    echo -e "\033[0;31m[ERROR]\033[0m Failed to change shell for $REAL_USER"
    exit 1
fi

echo -e "\033[0;32m[SUCCESS]\033[0m Shell changed back to bash for $REAL_USER"
echo "Launching bash..."

# Switch to the target user if not already that user
if [ "$USER" != "$REAL_USER" ]; then
    su - "$REAL_USER" -c "exec bash -l"
else
    exec bash -l
fi
OFF_EOF

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "\033[0;32m[SUCCESS]\033[0m Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Usage:"
echo "  Regular user:  z-on  (will prompt for sudo password)"
echo "  Regular user:  sudo z-on"
echo "  Root user:     z-on  (no sudo needed)"
echo ""
echo "  Regular user:  z-off  (will prompt for sudo password)"
echo "  Regular user:  sudo z-off"
echo "  Root user:     z-off  (no sudo needed)"
echo ""