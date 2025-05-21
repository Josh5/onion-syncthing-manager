#!/bin/sh
###
# title: Disable Syncthing
# description: Disables the Syncthing init scripts.
###

cd "${appdir:?}"
. "${appdir:?}/menu/bb-menu.sh"

print_title "Disabling Syncthing init script"

if rm -f "${sysdir:?}/startup/syncthing-startup.sh"; then
    echo "  Removed init script."
    press_any_key_to_exit 0
fi
echo "  Failed to remove init script."
echo "  Syncthing will continue to run on next boot."
echo "  You can manually disable it by removing the file:"
echo "  '.tmp_update/startup/syncthing-startup.sh'"
exit 1
