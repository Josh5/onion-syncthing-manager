#!/bin/sh
###
# File: launch.sh
# Project: src
# File Created: Tuesday, 20th May 2025 12:48:08 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 23rd May 2025 10:58:31 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export appdir=$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)
export sysdir="/mnt/SDCARD/.tmp_update"
export miyoodir="/mnt/SDCARD/miyoo"
export LD_LIBRARY_PATH="${appdir:?}/lib:/lib:/config/lib:${miyoodir:?}/lib:${sysdir:?}/lib:${sysdir:?}/lib/parasyte"
export PATH="${sysdir:?}/bin:${PATH:-}"

${sysdir:?}/bin/st -q -e "${appdir:?}/menus/run.sh"
