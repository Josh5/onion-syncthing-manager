#!/bin/sh
###
# File: common.sh
# Project: menu
# File Created: Tuesday, 20th May 2025 12:41:52 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 21st May 2025 12:29:14 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###

cd "$appdir/"
export sysdir="${appdir:?}/../../.tmp_update"
export miyoodir="${appdir:?}/../../miyoo"
export LD_LIBRARY_PATH="$appdir/lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
export PATH="$sysdir/bin:$PATH"

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
