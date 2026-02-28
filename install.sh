#!/bin/bash

# This script will install the necessary configurations.

# Fix z-off script sed command
sed -i.bak '/^source ~/.bashrc/d' ~/.bashrc

# Other installation commands here...