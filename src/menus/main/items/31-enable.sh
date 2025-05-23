#!/bin/sh
###
# title: Enable Syncthing
# description: Enables the Syncthing init scripts.
###

cd "${appdir:?}"
. "${appdir:?}/menus/common.sh"

print_title "Enabling Syncthing init script"

mkdir -p "${sysdir:?}/startup"
mkdir -p "${sysdir:?}/checkoff"
ln -sf "${appdir:?}/bin/stop.sh" "${sysdir:?}/checkoff/syncthing-checkoff.sh"
ln -sf "${appdir:?}/bin/start.sh" "${sysdir:?}/startup/syncthing-startup.sh"

echo "  Installed init scripts."
press_any_key_to_exit 0
