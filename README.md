# Zsh Shell / Bash Shell Switcher
Zsh / Bash Auto-Switcher Debian 12 /13

# Zsh-Bash Switcher 🚀
Easily toggle between a custom Zsh setup and standard Bash in terminal z-on for Zsh z-off for Bash shell

In the Zsh shell, beyond the Up and Down arrows for history navigation, there are several "power user" shortcuts (mostly based on Emacs keybindings) that let you manipulate text and navigate the command line much faster. 

Essential Navigation & History
Ctrl + R: Search backward through your history interactively.
Ctrl + P / Ctrl + N: Move to the Previous or Next command in history (same as Up/Down arrows).
Ctrl + A / Ctrl + E: Jump immediately to the Actual beginning or End of the line.
Alt + F / Alt + B: Move the cursor Forward or Backward by one full word.
Tab: Auto-complete commands, filenames, or paths. 

Editing & Deletion
Ctrl + W: Delete the word immediately before the cursor.
Ctrl + U: Delete the entire line (in Zsh).
Ctrl + K: Delete (kill) everything from the cursor to the end of the line.
Ctrl + Y: Paste ("yank") back the last text you deleted with Ctrl+W, Ctrl+U, or Ctrl+K.
Ctrl + _: Undo the last change to the command line. 

Process & Management
Ctrl + L: Clear the terminal screen while keeping your current command line intact.
Ctrl + C: Interrupt and kill the currently running process.
Ctrl + Z: Suspend the current process and move it to the background.

To see a complete list of all currently active keybindings in your specific shell, you can run the command bindkey in terminal

### 📥 Installation

Copy and paste this command into your terminal:
curl -sSL https://raw.githubusercontent.com/TerryClaiborne/Zsh-Bash/main/install.sh | sudo bash
