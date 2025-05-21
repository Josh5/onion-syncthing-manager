#!/bin/sh
###
# File: bb-menu.sh
# Project: menu
# File Created: Tuesday, 20th May 2025 12:42:44 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 21st May 2025 7:26:01 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

TTY_SIZE="$(stty size 2>/dev/null)"
TROWS="$(echo "${TTY_SIZE}" | awk '{print $1}')"
TCOLS="$(echo "${TTY_SIZE}" | awk '{print $2}')"

# User inputs
PAD_D_UP="1B 5B 41"
PAD_D_DOWN="1B 5B 42"
PAD_A="20" # A = space
PAD_B="7F" # B = backspace

# Create any needed directories
mkdir -p \
    "${appdir:?}/logs"

print_title() {
    echo "**** ${@:?} ****"
}

print_step_header() {
    echo "  - ${@:?}"
}

print_step_error() {
    echo -e "    \e[31mERROR: \e[33m${@:?}\e[0m"
}

press_any_key_to_exit() {
    local exit_code=${1:-0}
    echo
    echo "Press any key to return [${exit_code:?}]..."
    IFS= read -rsn1 _
    echo "..."
    exit $exit_code
}

parse_metadata() {
    # Reads `## key: value` from script headers
    awk '/^## /{sub(/^## /,""); print}' "$1"
}

delay_on_error() {
    echo
    echo "❌ An error occurred. See above for more information."
    echo "Returning to menu in 5 seconds..."
    sleep 5
    while read -rs -t 0.1; do :; done
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

generate_menu_items_ini() {
    local items_path="$1"
    local include_mode="$2" # should be either "include_quit" or "include_back"
    local index=1
    local output=""

    for script in "$items_path"/*.sh; do
        key="item$index"

        # Extract title and description from the script header
        title=$(head -n 20 "$script" | grep '^# *title:' | cut -d':' -f2- | sed 's/^ *//')
        desc=$(head -n 20 "$script" | grep '^# *description:' | cut -d':' -f2- | sed 's/^ *//')

        output="$output
${key}.title=$title
${key}.description=$desc
${key}.exec=$script"
        index=$((index + 1))
    done

    # Append Quit or Back option
    if [ "$include_mode" = "include_quit" ]; then
        output="$output
item999.title=Quit
item999.description=Quit back to OnionOS.
item999.exec=<EXIT>"
    elif [ "$include_mode" = "include_back" ]; then
        output="$output
item999.title=Back
item999.description=Go back to previous menu.
item999.exec=<EXIT>"
    fi

    echo "$output"
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
    local title="$1"
    local selected="$2"
    local config_ini="$3"

    local inner_width=$((TCOLS - 3))
    local usable_rows=$((TROWS - 1))
    local row_count=0

    clear

    # Top border and title
    printf "+%s+\n" "$(printf -- '-%.0s' $(seq 1 "$inner_width"))"

    # Centered menu title
    local formatted=":: ${title:-Menu} ::"
    local pad_left=$(((inner_width - ${#formatted}) / 2))
    printf "|%*s%s%*s|\n" "$pad_left" "" "$formatted" $((inner_width - pad_left - ${#formatted})) ""

    # Divider
    printf "+%s+\n" "$(printf -- '-%.0s' $(seq 1 "$inner_width"))"

    # Menu items
    for key in $(echo "$config_ini" | grep '\.title=' | cut -d'.' -f1 | sort -u); do
        item_title=$(echo "$config_ini" | grep "^${key}.title=" | cut -d'=' -f2-)
        if [ "$key" = "$selected" ]; then
            printf "| > %-*s |\n" $((inner_width - 4)) "$item_title"
        else
            printf "|   %-*s |\n" $((inner_width - 4)) "$item_title"
        fi
        row_count=$((row_count + 1))
    done

    local remaining=$((usable_rows - 4 - row_count))
    while [ "$remaining" -gt 0 ]; do
        printf "|%*s|\n" "$inner_width" ""
        remaining=$((remaining - 1))
    done

    # Bottom border
    printf "+%s+\n" "$(printf -- '-%.0s' $(seq 1 "$inner_width"))"
}

create_menu() {
    local config_ini="$1"
    local menu_title selected_key include_back include_quit keylist=""
    local selected_index=0 scroll_pid
    local screen_output

    menu_title=$(echo "$config_ini" | grep '^menu_title=' | cut -d'=' -f2-)
    selected_key=$(echo "$config_ini" | grep '^selected=' | cut -d'=' -f2-)
    include_back=$(echo "$config_ini" | grep '^include_back=' | cut -d'=' -f2-)
    include_quit=$(echo "$config_ini" | grep '^include_quit=' | cut -d'=' -f2-)

    # Get all item keys
    keylist=$(echo "$config_ini" | grep '^[a-zA-Z0-9]*\.title=' | cut -d'.' -f1 | sort -u)
    key_count=$(echo "$keylist" | wc -w)

    # Get first key as default selected
    [ -z "$selected_key" ] && selected_key=$(echo "$keylist" | awk '{print $1}')

    # Scroll output row (bottom of screen)
    local scroll_line=$((TROWS - 1))

    # Begin input loop
    local menu_back="f"
    while true; do
        # Pre-fetch the full menu output. Then draw it
        local screen_output
        screen_output=$(draw_menu "$menu_title" "$selected_key" "$config_ini")
        if [ "${menu_back:-}" = "t" ]; then
            while read -t 1 discard; do echo "..."; done
            menu_back="f"
        fi
        clear
        echo -e "$screen_output"

        # Scroll line
        desc=$(echo "$config_ini" | grep "^${selected_key}.description=" | cut -d'=' -f2-)
        scroll_description "$desc" &
        scroll_pid=$!

        # Read key input
        IFS= read -rsn1 input
        if [ "$input" = $'\x1b' ]; then
            IFS= read -rsn2 rest
            input="$input$rest"
        fi

        # Convert input to hex string for matching
        local input_hex=$(echo -n "${input:-}" | hexdump -v -e '/1 "%02X "' | sed 's/ *$//')
        # Add logging to make it easier to debug new input devices
        echo "Key pressed: [${input:-}] HEX: [${input_hex:-}]" >>"${appdir:?}/logs/keys.log"

        # Kill scroll loop and clear scroll line
        kill "${scroll_pid:-}" 2>/dev/null
        printf "\033[%s;1H\033[K" "${scroll_line:-}"

        case "${input_hex:-}" in
        "${PAD_D_UP:?}")
            selected_index=$(((selected_index - 1 + key_count) % key_count))
            ;;
        "${PAD_D_DOWN:?}")
            selected_index=$(((selected_index + 1) % key_count))
            ;;
        "${PAD_A:?}" | "")
            exec=$(echo "$config_ini" | grep "^${selected_key}.exec=" | cut -d'=' -f2-)
            if [ "$exec" = "<EXIT>" ]; then
                echo "Exit!"
                exit 0
            fi
            clear
            sh -c "$exec" || delay_on_error
            menu_back="t"
            ;;
        "${PAD_B:?}")
            echo return 0
            ;;
        *)
            echo "(^ Unhandled by menu navigation)" >>"${appdir:?}/logs/keys.log"
            ;;
        esac

        # Refresh selected_key after navigation
        selected_key=$(echo "$keylist" | awk "NR==$((selected_index + 1))")
    done
}
