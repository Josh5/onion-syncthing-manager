#!/bin/sh
###
# File: start.sh
# Project: bin
# File Created: Tuesday, 20th May 2025 4:33:32 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 23rd May 2025 11:00:06 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

appdir="/mnt/SDCARD/App/SyncthingManager"
export sysdir="${appdir:?}/../../.tmp_update"
export miyoodir="${appdir:?}/../../miyoo"
export LD_LIBRARY_PATH="$appdir/lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
export PATH="$sysdir/bin:$PATH"

syncthing_pid=$(pidof syncthing)

IP=$(ip route get 1 | awk '{print $NF;exit}')
if [ -z "${syncthing_pid:-}" ]; then
    # Enforce required configuration
    if [ ! -f "${appdir:?}/config/config.xml" ]; then
        sed -i 's|<listenAddress>tcp://0.0.0.0:41383</listenAddress>|<listenAddress>default</listenAddress>|' "${appdir:?}/config/config.xml"
        sed -i 's|<address>127.0.0.1:40379</address>|<address>0.0.0.0:8384</address>|' "${appdir:?}/config/config.xml"
        sed -i "s|<address>127.0.0.1:8384</address>|<address>0.0.0.0:8384</address>|g" "${appdir:?}/config/config.xml"
    fi
    sync

    # Run Syncthing
    echo "  Starting Syncthing"
    "${appdir:?}/share/syncthing/syncthing" serve --home="${appdir:?}/config/" >"${appdir:?}/logs/syncthing.log" 2>&1 &
else
    echo "  Syncthing already running"
fi

echo "    - Web Address: ${IP:-}:8384"
echo "    - Default username: onion"
echo "    - Default password: onion"
