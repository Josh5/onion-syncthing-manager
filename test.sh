#!/usr/bin/env bash
###
# File: test.sh
# Project: onion-syncthing-manager
# File Created: Tuesday, 20th May 2025 2:15:48 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 23rd May 2025 10:12:20 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

# Path to your main.sh script
SCRIPT_PATH="$(dirname "$(readlink -f "$0")")/src/menus/run.sh"

# Terminal dimensions (characters, not pixels)
COLS=53
ROWS=29

# Terminal title
TITLE="Syncthing Manager"

# Check if st is available
if command -v st >/dev/null 2>&1; then
    st -t "$TITLE" -g ${COLS}x${ROWS} -e "$SCRIPT_PATH"
elif command -v xterm >/dev/null 2>&1; then
    xterm -T "$TITLE" -geometry ${COLS}x${ROWS} -e "$SCRIPT_PATH"
else
    echo "Error: Neither 'st' nor 'xterm' is installed. Please install one to run the menu."
    exit 1
fi

echo "Terminal exited"
