#!/bin/bash
#
# Copyright (C) 2026 Terry L. Claiborne, KC3KMV
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Zsh Shell / Bash Shell Switcher - Debian 12 Debian 13
#
# Easily toggle between a custom Zsh setup and standard Bash in terminal z-on for Zsh z-off for Bash shell
# In the Zsh shell, beyond the Up and Down arrows for history navigation, there are several "power user" shortcuts (mostly based on Emacs keybindings) that let you manipulate text and navigate the command line much faster.
# Essential Navigation & History Ctrl + R: Search backward through your history interactively. Ctrl + P / Ctrl + N: Move to the Previous or Next command in history (same as Up/Down arrows). Ctrl + A / Ctrl + E: Jump immediately to the Actual beginning or End of the line. Alt + F / Alt + B: Move the cursor Forward or Backward by one full word. Tab: Auto-complete commands, filenames, or paths.
# Editing & Deletion Ctrl + W: Delete the word immediately before the cursor. Ctrl + U: Delete the entire line (in Zsh). Ctrl + K: Delete (kill) everything from the cursor to the end of the line. Ctrl + Y: Paste ("yank") back the last text you deleted with Ctrl+W, Ctrl+U, or Ctrl+K. Ctrl + _: Undo the last change to the command line.
# Process & Management Ctrl + L: Clear the terminal screen while keeping your current command line intact. Ctrl + C: Interrupt and kill the currently running process. Ctrl + Z: Suspend the current process and move it to the background.
# To see a complete list of all currently active keybindings in your specific shell, you can run the command bindkey in terminal
#
# Check if script is run as root

if [ "$EUID" -ne 0 ]; then 
  echo "Please run with sudo: sudo bash install.sh"
  exit
fi

echo "Installing z-on and z-off scripts..."

# Create the z-on script
cat << 'EOF' > /usr/local/bin/z-on
#!/bin/bash
sudo apt update
sudo apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions
chsh -s $(which zsh)

cat << 'ZSHRC' > ~/.zshrc
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE
setopt AUTO_CD EXTENDED_GLOB
setopt interactive_comments
unsetopt NOMATCH

precmd() {
  print -rP "%F{red}%n %f- %F{white}%m %f[%F{blue}%1~%f]"
}

PROMPT='%F{cyan}%D{%a %b %d} %F{yellow}%t %F{green}➤ %f'

alias apt='sudo apt'

update-system() {
    sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt clean
}

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
ZSHRC

if ! grep -q "exec zsh" ~/.bashrc 2>/dev/null; then
  cat << 'FALLBACK' >> ~/.bashrc
if [[ -t 1 && -x $(command -v zsh) ]]; then
  exec zsh -l
fi
FALLBACK
fi

if [ -x "$(command -v zsh)" ]; then
    exec zsh -l
fi
EOF

# Create the z-off script
cat << 'EOF' > /usr/local/bin/z-off
#!/bin/bash
TARGET_HOME="$HOME"
TARGET_USER="$USER"

cp /etc/skel/.bashrc "$TARGET_HOME/.bashrc"

sed -i '/exec zsh/d' "$TARGET_HOME/.bashrc"
sed -i '/zsh -l/d' "$TARGET_HOME/.bashrc"

echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\\\$\[\033[00m\] '" >> "$TARGET_HOME/.bashrc"

echo "alias apt='sudo apt'" >> "$TARGET_HOME/.bashrc"

sudo chsh -s $(which bash) "$TARGET_USER"

exec bash -l
EOF

# Set executable permissions
chmod +x /usr/local/bin/z-on /usr/local/bin/z-off

echo "-------------------------------------------"
echo "SUCCESS: Installation Complete!"
echo "Commands available: z-on, z-off"
echo "-------------------------------------------"
