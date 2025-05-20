#!/usr/bin/env bash
###
# File: stop.sh
# Project: bin
# File Created: Tuesday, 20th May 2025 4:33:36 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 20th May 2025 4:58:17 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

appdir="/mnt/SDCARD/App/Syncthing4Onion"
export sysdir="${appdir:?}/../../.tmp_update"
export miyoodir="${appdir:?}/../../miyoo"
export LD_LIBRARY_PATH="$appdir/lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
export PATH="$sysdir/bin:$PATH"

syncthing_pid=$(pidof syncthing)

if [ -z "${syncthing_pid:-}" ]; then
    echo "  Syncthing is not running."
else
    echo "  Sending SIGTERM to syncthing (pid: ${syncthing_pid:?})..."
    kill -TERM "${syncthing_pid:?}"

    # Wait up to 3 seconds, checking every 0.2s
    i=0
    while [ $i -lt 15 ]; do
        sleep 0.2
        if ! kill -0 "${syncthing_pid:?}" 2>/dev/null; then
            echo "  Syncthing stopped gracefully."
            return 0
        fi
        i=$((i + 1))
    done

    echo "  Syncthing did not stop after SIGTERM, sending SIGKILL..."
    kill -KILL "${syncthing_pid:?}"

    # Wait up to 2 more seconds
    i=0
    while [ $i -lt 10 ]; do
        sleep 0.2
        if ! kill -0 "${syncthing_pid:?}" 2>/dev/null; then
            echo "  Syncthing was forcefully stopped."
            return 0
        fi
        i=$((i + 1))
    done

    echo "  Error: Syncthing could not be stopped."
    return 1
fi
