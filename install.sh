#!/bin/bash

# z-on script to add zsh launcher block to .bashrc
# BEGIN Z-ON LAUNCHER
if [ -z "$ZSH_LAUNCHER_LOADED" ]; then
    export ZSH_LAUNCHER_LOADED=true
    # Add your zsh launcher lines below this line
    echo 'source ~/path/to/your/zsh_launcher.sh' >> ~/.bashrc
fi
# END Z-ON LAUNCHER


# z-off script to remove zsh launcher block from .bashrc
# Using `sed` to remove from BEGIN to END markers inclusively
if [ -n "$ZSH_LAUNCHER_LOADED" ]; then
    sed -i '/# BEGIN Z-ON LAUNCHER/,/# END Z-ON LAUNCHER/d' ~/.bashrc
    unset ZSH_LAUNCHER_LOADED
fi
