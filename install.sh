#!/bin/bash
set -euo pipefail

#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
#
# Zsh Shell / Bash Shell Switcher - Debian 12 Debian 13
# Universal version - works for any user and root

# ────────────────────────────────────────────────
# UNIVERSAL USER DETECTION
# ────────────────────────────────────────────────

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

echo "Detected user: $REAL_USER"
echo "Home directory: $REAL_HOME"

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

if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31m[ERROR]\033[0m z-on requires sudo."
    exit 1
fi

echo "Updating packages..."
apt update > /dev/null 2>&1

echo "Installing zsh and plugins..."
apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions > /dev/null 2>&1

echo "Configuring .zshrc for $REAL_USER..."
cat << 'ZSHRC' > "$REAL_HOME/.zshrc"
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE
setopt AUTO_CD EXTENDED_GLOB
unsetopt NOMATCH
precmd() { print -rP "%F{red}%n %f- %F{white}%m %f[%F{blue}%1~%f]"; }
PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%t %F{green}➤ %f'
alias apt='sudo apt'
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSHRC
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.zshrc"

# Inject Zsh launcher into .bashrc safely
if ! grep -q "BEGIN Z-ON LAUNCHER" "$REAL_HOME/.bashrc" 2>/dev/null; then
    cat << 'BASH_LAUNCH' >> "$REAL_HOME/.bashrc"

# BEGIN Z-ON LAUNCHER
if [[ -t 1 && -x $(command -v zsh) ]]; then
  exec zsh -l
fi
# END Z-ON LAUNCHER
BASH_LAUNCH
fi

chsh -s "$(command -v zsh)" "$REAL_USER"
echo -e "\033[0;32m[SUCCESS]\033[0m Switching to Zsh..."

# Force immediate switch
if [ "$USER" != "$REAL_USER" ]; then
    exec su - "$REAL_USER"
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

# 1. Detect Real User
if [ "$EUID" -eq 0 ]; then
    REAL_USER="${SUDO_USER:-root}"
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
    echo -e "\033[0;31m[ERROR]\033[0m z-off requires sudo. Run: sudo z-off"
    exit 1
fi

echo "Reverting to bash for $REAL_USER..."

# 2. Cleanup .bashrc and change system default shell
[ -f "$REAL_HOME/.bashrc" ] && sed -i '/# BEGIN Z-ON LAUNCHER/,/# END Z-ON LAUNCHER/d' "$REAL_HOME/.bashrc"
chsh -s /usr/bin/bash "$REAL_USER"

echo -e "\033[0;32m[SUCCESS]\033[0m Default shell is now Bash."

# 3. THE FORCE-REPLACE LOGIC
# This kills the current Zsh process and replaces it with Bash
if [ "$USER" != "$REAL_USER" ]; then
    # If running via sudo, drop root and exec a fresh bash login shell as the user
    exec su - "$REAL_USER"
else
    # If running as direct root, replace current shell with root bash
    exec /usr/bin/bash --login
fi
OFF_EOF

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "\033[0;32m[SUCCESS]\033[0m Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Run 'z-on' to start Zsh or 'z-off' to return to Bash."
