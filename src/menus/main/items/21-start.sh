#!/bin/sh
###
# title: Start Syncthing
# description: Starts Syncthing if it is not already running.
###

cd "${appdir:?}"
. "${appdir:?}/menus/common.sh"

print_title "Starting Syncthing"

"${appdir:?}/bin/start.sh"
press_any_key_to_exit $?
