#!/bin/sh
###
# File: main.sh
# Project: menu
# File Created: Tuesday, 20th May 2025 12:43:00 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 20th May 2025 5:53:18 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export appdir=$(
    cd -- "$(dirname "$0")/../" >/dev/null 2>&1
    pwd -P
)
cd "${appdir:?}"

. "${appdir:?}/menu/common.sh"
. "${appdir:?}/menu/bb-menu.sh"

# Dynamically build JSON map of menu items
item_entries=$(generate_menu_items_json "${appdir:?}/menu/items")
menu_json=$(echo "{ \"items\": $item_entries}" | jq '. + {
  "menu_title": "Syncthing Manager",
  "include_back": false,
  "include_quit": true
}')

clear
create_menu "$menu_json"
res=$?
[ $res -ne 0 ] && echo "An error occurred." && exit $res
