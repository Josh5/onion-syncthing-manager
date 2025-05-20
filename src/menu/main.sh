#!/bin/sh
###
# File: main.sh
# Project: menu
# File Created: Tuesday, 20th May 2025 12:43:00 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 20th May 2025 6:10:57 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export appdir=$(
    cd -- "$(dirname "$0")/../" >/dev/null 2>&1
    pwd -P
)
cd "${appdir:?}"

. "${appdir:?}/menu/common.sh"
. "${appdir:?}/menu/bb-menu.sh"

# Dynamically build menu items
item_entries=$(generate_menu_items_ini "${appdir:?}/menu/items" "include_quit")
menu_config=$(
    cat <<EOF
menu_title=Syncthing Manager
include_back=false
include_quit=true
selected=item1
${item_entries}
EOF
)

clear
create_menu "$menu_config"
res=$?
[ $res -ne 0 ] && echo "An error occurred." && exit $res
