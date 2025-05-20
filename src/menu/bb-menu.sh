#!/bin/sh
###
# File: bb-menu.sh
# Project: menu
# File Created: Tuesday, 20th May 2025 12:42:44 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 20th May 2025 5:52:24 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export TCOLS=53
export TROWS=29

print_header() {
    echo "==== $1 ===="
}

print_error() {
    echo "!! ERROR: $1"
}

run_menu_item() {
    script="$1"
    . ./common.sh
    . "$script"
    return $?
}

parse_metadata() {
    # Reads `## key: value` from script headers
    awk '/^## /{sub(/^## /,""); print}' "$1"
}

generate_menu_items_json() {
    local items_path="$1"
    local item_entries=""
    local index=1
    local key

    for f in "${appdir:?}/menu/items/"*.sh; do
        key="item$index"
        item_entries="$item_entries\"$key\": \"${f}\","
        index=$((index + 1))
    done

    # Remove trailing comma
    item_entries="${item_entries%,}"

    # Wrap in items block
    printf '{ %s }' "$item_entries"
}

# Extract metadata from script
get_script_metadata() {
    local script="$1"
    awk -F ': ' '
    BEGIN { title=""; desc=""; in_header=0 }
    /^###/        { in_header=1; next }
    /^# title:/    { if (in_header) title=$2; next }
    /^# description:/ { if (in_header) desc=$2; next }
    /^###/        { in_header=0; next }
    END {
        gsub(/"/, "\\\"", title)
        gsub(/"/, "\\\"", desc)
        printf "{ \"title\": \"%s\", \"description\": \"%s\" }", title, desc
    }' "$script"
}

scroll_description() {
    local desc="$1"
    local width=$((TCOLS - 6))
    local delay=1
    local spacer="   "
    local scroll_line=$((TROWS - 1)) # last visible line

    # If the text fits, show it statically and skip scrolling
    if [ ${#desc} -le $((width - 2)) ]; then
        printf "\033[%s;2H| %-*s |\n" "$scroll_line" $((width - 2)) "$desc"
        return
    fi

    # Prepare scrolling text (wrap twice for smooth loop)
    local scroll_text="${desc}${spacer}${desc}${spacer}"
    local i=0
    local scroll_text_len=${#scroll_text}

    while :; do
        local part=$(echo "$scroll_text" | cut -c $((i + 1))-$((i + width)))
        printf "\033[%s;2H| %-*s |\n" "$scroll_line" $((width - 2)) "$part"
        i=$(((i + 1) % scroll_text_len))
        sleep "$delay"
        delay=0.1
    done
}

draw_menu() {
    local json="$1"
    local selected=$(echo "$json" | jq -r '.selected_item')
    local keys=$(echo "$json" | jq -r '.items | keys[]')
    local title=$(echo "$json" | jq -r '.menu_title // "Menu"')

    local inner_width=$((TCOLS - 3))
    local usable_rows=$((TROWS - 1))
    local row_count=0

    clear

    # Top border and title
    printf "+%s+\n" "$(printf -- '-%.0s' $(seq 1 "$inner_width"))"

    # Centered menu title
    local formatted=":: ${title} ::"
    local pad_left=$(((inner_width - ${#formatted}) / 2))
    printf "|%*s%s%*s|\n" "$pad_left" "" "$formatted" $((inner_width - pad_left - ${#formatted})) ""

    # Divider
    printf "+%s+\n" "$(printf -- '-%.0s' $(seq 1 "$inner_width"))"

    # Menu items
    for key in $keys; do
        entry_title=$(echo "$json" | jq -r --arg k "$key" '.items[$k].title')
        if [ "$key" = "$selected" ]; then
            printf "| > %-*s |\n" $((inner_width - 4)) "$entry_title"
        else
            printf "|   %-*s |\n" $((inner_width - 4)) "$entry_title"
        fi
        row_count=$((row_count + 1))
    done

    # Fill remainder
    local header_lines=3
    local footer_lines=1
    local remaining_lines=$((usable_rows - header_lines - row_count - footer_lines))

    while [ "$remaining_lines" -gt 0 ]; do
        printf "|%*s|\n" "$inner_width" ""
        remaining_lines=$((remaining_lines - 1))
    done

    # Bottom border
    printf "+%s+\n" "$(printf -- '-%.0s' $(seq 1 "$inner_width"))"
}

create_menu() {
    local config_json="$1"
    local items_json selected_key exec draw_json
    local include_back include_quit scroll_pid menu_title
    local keylist selected_index=0 key_count=0

    include_back=$(echo "$config_json" | jq -r '.include_back // false')
    include_quit=$(echo "$config_json" | jq -r '.include_quit // false')
    menu_title=$(echo "$config_json" | jq -r '.menu_title // "Menu"')

    # Build enriched items JSON with metadata from headers
    items_json=$(echo "$config_json" | jq -r '.items | to_entries[] | "\(.key)|\(.value)"' | while IFS='|' read -r key script; do
        meta=$(get_script_metadata "$script")
        title=$(echo "$meta" | jq -r '.title')
        desc=$(echo "$meta" | jq -r '.description')
        printf '"%s": { "title": "%s", "description": "%s", "exec": "%s" },\n' "$key" "$title" "$desc" "$script"
    done)

    if [ "$include_quit" = "true" ]; then
        items_json="${items_json}\"item999\": { \"title\": \"Quit\", \"description\": \"Quit back to OnionOS.\", \"exec\": \"<EXIT>\" }"
    elif [ "$include_back" = "true" ]; then
        items_json="${items_json}\"item999\": { \"title\": \"Back\", \"description\": \"Go back to previous menu.\", \"exec\": \"<EXIT>\" }"
    else
        items_json="${items_json%,}"
    fi

    # Finalize structured menu JSON
    items_json="{ ${items_json} }"

    # Store the keys as a space-separated string
    keylist=$(echo "$items_json" | jq -r 'keys | join(" ")')
    key_count=$(echo "$keylist" | wc -w)

    # Get first key as default selected
    selected_key=$(echo "$keylist" | cut -d' ' -f1)

    # Scroll output row (bottom of screen)
    local scroll_line=$((TROWS - 1))

    # Begin input loop
    while true; do
        draw_json=$(echo "$items_json" | jq --arg sel "$selected_key" --arg title "$menu_title" '{ selected_item: $sel, menu_title: $title, items: . }')
        draw_menu "$draw_json"

        # Start scroll line
        desc=$(echo "$items_json" | jq -r --arg k "$selected_key" '.[$k].description')
        scroll_description "$desc" &
        scroll_pid=$!

        # Read key input
        IFS= read -rsn1 input
        [ "$input" = $'\x1b' ] && IFS= read -rsn2 rest && input+="$rest"

        # Kill scroll loop and clear scroll line
        kill "$scroll_pid" 2>/dev/null
        printf "\033[%s;1H\033[K" "$scroll_line"

        case "$input" in
        $'\x1b[A' | k)
            selected_index=$(((selected_index - 1 + key_count) % key_count))
            ;;
        $'\x1b[B' | j)
            selected_index=$(((selected_index + 1) % key_count))
            ;;
        "" | $'\n' | $'\r')
            exec=$(echo "$items_json" | jq -r --arg k "$selected_key" '.[$k].exec')
            if [ "$exec" = "<EXIT>" ]; then
                echo "Exit!"
                exit 0
            fi
            clear
            sh -c "$exec"
            ;;
        $'\x7f' | $'\x08')
            return 0
            ;;
        *)
            echo "Unhandled input: [$input]"
            sleep 2
            ;;
        esac

        # Refresh selected_key after navigation
        selected_key=$(echo "$keylist" | cut -d' ' -f$((selected_index + 1)))
    done
}
