#!/bin/bash
set -euo pipefail

# BEGIN Z-ON LAUNCHER
if [ -z "$BASH_VERSION" ]; then
    echo "This script is intended for use with bash."
    exit 1
fi

# Function to add the zsh launcher to .bashrc
z_on() {
    if ! grep -q "# BEGIN Z-ON LAUNCHER" ~/.bashrc; then
        echo "\n# BEGIN Z-ON LAUNCHER" >> ~/.bashrc
        echo "source /path/to/zsh_launcher.zsh" >> ~/.bashrc
        echo "# END Z-ON LAUNCHER" >> ~/.bashrc
    else
        echo "Z-on launcher already exists in .bashrc."
    fi
}

# Function to remove the zsh launcher from .bashrc
z_off() {
    sed -i.bak '/# BEGIN Z-ON LAUNCHER/,/# END Z-ON LAUNCHER/d' ~/.bashrc
}
# Usage example
# z_on  # To add
# z_off # To remove
# END Z-ON LAUNCHER