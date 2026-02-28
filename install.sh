#!/bin/bash

# Updated z-off script with safer sed pattern

# Start marker
START_MARKER='# BEGIN z-off'
END_MARKER='# END z-off'

# Use sed to modify the .bashrc without orphaning fi statements
sed -i "/$START_MARKER/,/$END_MARKER/d" ~/.bashrc
