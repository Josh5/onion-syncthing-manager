#!/usr/bin/env bash
###
# File: start.sh
# Project: bin
# File Created: Tuesday, 20th May 2025 4:33:32 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 20th May 2025 4:53:21 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

appdir="/mnt/SDCARD/App/Syncthing4Onion"
export sysdir="${appdir:?}/../../.tmp_update"
export miyoodir="${appdir:?}/../../miyoo"
export LD_LIBRARY_PATH="$appdir/lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
export PATH="$sysdir/bin:$PATH"

syncthing_pid=$(pidof syncthing)

if [ -z "${syncthing_pid:-}" ]; then
    "${appdir:?}/bin/syncthing" serve --home="${appdir:?}/config/" >"${appdir:?}/logs/syncthing.log" 2>&1 &
fi
