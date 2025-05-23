#!/bin/sh
###
# File: bb-menu.sh
# Project: menu
# File Created: Tuesday, 20th May 2025 12:42:44 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 23rd May 2025 10:22:37 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

# Create any needed directories
mkdir -p \
    "${appdir:?}/logs"

print_title() {
    echo "**** ${@:?} ****"
}

print_step_header() {
    echo "  - ${@:?}"
}

print_step_error() {
    echo -e "    \e[31mERROR: \e[33m${@:?}\e[0m"
}

press_any_key_to_exit() {
    local exit_code=${1:-0}
    echo
    echo "Press any key to return [${exit_code:?}]..."
    IFS= read -rsn1 _
    echo "..."
    exit $exit_code
}

parse_metadata() {
    # Reads `## key: value` from script headers
    awk '/^## /{sub(/^## /,""); print}' "$1"
}

delay_on_error() {
    echo
    echo "❌ An error occurred. See above for more information."
    echo "Returning to menu in 5 seconds..."
    sleep 5
    while read -rs -t 0.1; do :; done
}
