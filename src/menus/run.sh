#!/bin/sh
###
# File: run.sh
# File Created: Tuesday, 20th May 2025 12:43:00 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 23rd May 2025 10:23:56 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export appdir=$(cd "$(dirname "$0")/../" && pwd -P)
export sysdir="${appdir:?}/../../.tmp_update"
export miyoodir="${appdir:?}/../../miyoo"
export LD_LIBRARY_PATH="${appdir:?}/lib:/lib:/config/lib:${miyoodir:?}/lib:${sysdir:?}/lib:${sysdir:?}/lib/parasyte"
export PATH="${appdir:?}/bin:${sysdir:?}/bin:${PATH:-}"

# Display menu
bb-menu --bg-color=black "${appdir:?}/menus/main"
res=$?
[ $res -ne 0 ] && echo "An error occurred." && exit $res
