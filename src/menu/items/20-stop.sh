#!/bin/sh
###
# title: Stop Syncthing
# description: Stops Syncthing if it is running.
###

cd "${appdir:?}"
. "${appdir:?}/menu/bb-menu.sh"

print_title "Stopping Syncthing"

"${appdir:?}/bin/stop.sh"
press_any_key_to_exit $?
