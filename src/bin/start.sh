#!/bin/sh
###
# File: start.sh
# Project: bin
# File Created: Tuesday, 20th May 2025 4:33:32 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 21st May 2025 5:56:27 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

appdir="/mnt/SDCARD/App/SyncthingManager"
export sysdir="${appdir:?}/../../.tmp_update"
export miyoodir="${appdir:?}/../../miyoo"
export LD_LIBRARY_PATH="$appdir/lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
export PATH="$sysdir/bin:$PATH"

syncthing_pid=$(pidof syncthing)

if [ -z "${syncthing_pid:-}" ]; then
    IP=$(ip route get 1 | awk '{print $NF;exit}')

    # Enforce required configuration
    if [ ! -f "${appdir:?}/config/config.xml" ]; then
        sed -i 's|<listenAddress>tcp://0.0.0.0:41383</listenAddress>|<listenAddress>default</listenAddress>|' "${appdir:?}/config/config.xml"
        sed -i 's|<address>127.0.0.1:40379</address>|<address>0.0.0.0:8384</address>|' "${appdir:?}/config/config.xml"
        sed -i "s|<address>127.0.0.1:8384</address>|<address>0.0.0.0:8384</address>|g" "${appdir:?}/config/config.xml"
    fi
    sync

    # Run Syncthing
    echo "  Starting Syncthing"
    echo "    - Web Address: ${IP:-}:8384"
    echo "    - Default username: onion"
    echo "    - Default password: onion"
    "${appdir:?}/bin/syncthing" serve --home="${appdir:?}/config/" >"${appdir:?}/logs/syncthing.log" 2>&1 &
fi
