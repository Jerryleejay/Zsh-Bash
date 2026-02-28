# Zsh ↔ Bash Toggle for Debian

**Easily switch** between a clean, powerful **Zsh** setup and standard **Bash** on Debian 12 / 13.

- Type `z-on` → get enhanced Zsh with syntax highlighting, autosuggestions, smart history, and a nice prompt  
- Type `z-off` → instantly revert to stock Debian Bash  

No heavy frameworks, no bloat — just useful defaults.

## Features

- Lightweight Zsh configuration with:
  - zsh-autosuggestions & zsh-syntax-highlighting
  - Large shared history (50 000 entries, duplicates ignored)
  - Smart ↑/↓ arrows (search from beginning of typed command)
  - Modern colorful prompt (date/time + user@host/dir info)
  - Handy `update-system` command for full upgrades
- Safe & repeatable: backs up your `.zshrc`/`.bashrc`, skips redundant installs
- Full Emacs-style keybindings for fast editing (see list below)

## Zsh Power Shortcuts

Beyond Up/Down arrows for history:

**Navigation & History**  
- `Ctrl + R` — interactive backward history search  
- `Ctrl + P` / `Ctrl + N` — previous/next command  
- `Ctrl + A` / `Ctrl + E` — jump to beginning/end of line  
- `Alt + F` / `Alt + B` — forward/backward one word  
- `Tab` — auto-complete commands, files, paths  

**Editing & Deletion**  
- `Ctrl + W` — delete word before cursor  
- `Ctrl + U` — delete entire line  
- `Ctrl + K` — delete from cursor to end of line  
- `Ctrl + Y` — yank (paste) last deleted text  
- `Ctrl + _` — undo last change  

**Process & Management**  
- `Ctrl + L` — clear screen (keeps current command)  
- `Ctrl + C` — interrupt/kill current process  
- `Ctrl + Z` — suspend current process to background  

See all active bindings:  
bindkey

### 📥 Installation

Copy and paste this command into your terminal:
```bash
curl -sSL https://raw.githubusercontent.com/TerryClaiborne/Zsh-Bash/main/install.sh | sudo bash
```
