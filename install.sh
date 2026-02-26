#!/bin/bash
#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
# Final version with restored prompt style – February 2026
#
# Zsh ↔ Bash toggle for Debian 12 / 13 / Raspberry Pi OS
#   z-on  → enable nice Zsh (restored prompt style)
#   z-off → remove additions + switch to bash (warning visible)

set -euo pipefail

[[ ${EUID} -ne 0 ]] && {
    echo "Error: Run with sudo"
    exit 1
}

mkdir -p /usr/local/bin

# z-on
cat > /usr/local/bin/z-on << 'EOT'
#!/usr/bin/env bash
set -euo pipefail

echo "Enabling nice Zsh setup..."

if ! dpkg-query -W -f='${Status}' zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null | grep -Eq "ok installed"; then
    DEBIAN_FRONTEND=noninteractive apt update -qq
    DEBIAN_FRONTEND=noninteractive apt install -yqq zsh zsh-syntax-highlighting zsh-autosuggestions
fi

[ -f "${HOME}/.zshrc" ] && cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"

if ! grep -q "=== Zsh nice settings added by z-on ===" "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" << 'ZSHRC'

# === Zsh nice settings added by z-on ===
#     (remove this whole block with z-off if desired)

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS

setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS
unsetopt NOMATCH

# Restored prompt style (root - hostname [dir] date time ➤ )
PROMPT='%F{red}root - %m%f [%1~] %F{cyan}%D{%a %b %d} %F{yellow}%T %F{green}➤ %f'

alias apt='sudo apt'

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# === End of z-on nice settings ===
ZSHRC
fi

chsh -s "$(command -v zsh)" 2>/dev/null || true

exec zsh -l
EOT

# z-off
cat > /usr/local/bin/z-off << 'EOT'
#!/usr/bin/env bash
set -euo pipefail

if [ -n "${ZSH_VERSION+set}" ]; then
    echo "Error: Do NOT source z-off in Zsh. Just type: z-off"
    exit 1
fi

echo "Removing Zsh additions..."

[ -f "${HOME}/.zshrc" ] && cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
[ -f "${HOME}/.bashrc" ] && cp "${HOME}/.bashrc" "${HOME}/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"

sed -i '/=== Zsh nice settings added by z-on ===/,/=== End of z-on nice settings ===/d' "${HOME}/.zshrc" 2>/dev/null || true
sed -i '/exec.*zsh/d' "${HOME}/.bashrc" 2>/dev/null || true

chsh -s "$(command -v bash)" 2>/dev/null || true

echo ""
echo "Bash restored (only toggle additions removed)."
echo "• Your other customizations preserved."

echo ""
echo "Switching this terminal session to bash now..."
sleep 1.2

exec /bin/bash -l
EOT

chmod +x /usr/local/bin/z-on /usr/local/bin/z-off
