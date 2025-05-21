#!/bin/sh
###
# title: Install/Update Syncthing
# description: Install or update the latest Syncthing binary from the official releases and then restart the process.
###

cd "${appdir:?}"
. "${appdir:?}/menu/bb-menu.sh"

print_title "Installing/Updating Syncthing"

arch=$(uname -m)
case "$arch" in
x86_64) package_search_string="linux-amd64" ;;
aarch64) package_search_string="linux-arm64" ;;
armv7l) package_search_string="linux-arm-v1" ;;
*)
    echo "Unsupported arch: $arch"
    sleep 5
    exit 1
    ;;
esac

# Check for a new version to install
registry_package_json=$(curl -sk -H "Accept: application/vnd.github+json" https://api.github.com/repos/syncthing/syncthing/releases/latest)
if [ -z "${registry_package_json:-}" ]; then
    print_step_error "Failed to fetch the list of releases for Syncthing from GitHub"
fi
latest_package_version=$(echo ${registry_package_json:?} | jq -r '.tag_name')
latest_package_url=$(echo "${registry_package_json:?}" | jq -r '.assets[] | select(.name | test("'${package_search_string:?}'.*\\.tar.gz$"; "i"))' | jq -r '.browser_download_url')

print_step_header "Latest Syncthing version: ${latest_package_version:?}"

# Check if this is the currently installed version
if [ -f "${appdir:?}/share/syncthing/.current_version" ]; then
    print_step_header "Checking currently installed version"
    current_version=$(cat "${appdir:?}/share/syncthing/.current_version" 2>/dev/null || true)
    if [ "${current_version:-}" = "${latest_package_version:?}" ]; then
        echo "    Current version: ${latest_package_version:?}."
        echo "    If you wish to re-install syncthing, first"
        echo "    remove the contents in ./share/syncthing."
        press_any_key_to_exit 0
    fi
fi

# Clean up any temp files
if [ -d "${appdir:?}/.tmp" ]; then
    rm -rf "${appdir:?}/.tmp"
fi
mkdir -p "${appdir:?}/.tmp"

# Create required directories
mkdir -p \
    "${appdir:?}/bin" \
    "${appdir:?}/config" \
    "${appdir:?}/logs" \
    "${appdir:?}/share"

# Download the latest release
versioned_tar="${appdir:?}/share/syncthing-${latest_package_version:?}.tar.gz"
if [ -f "$versioned_tar" ]; then
    print_step_header "Using cached Syncthing release tarball for version ${latest_package_version:?}"
else
    print_step_header "Downloading Syncthing version ${latest_package_version:?}"
    mkdir -p "${appdir:?}/.tmp/syncthing-download"
    tmp_tar="${appdir:?}/.tmp/syncthing-download/syncthing.tar.gz"

    curl -Lk -o "$tmp_tar" "${latest_package_url:?}" || {
        echo "Download failed."
        exit 1
    }

    mv -f "$tmp_tar" "$versioned_tar"
fi

# Extract tarball
print_step_header "Extracting Syncthing release"
tmp_dir="${appdir:?}/.tmp/extracted"
mkdir -p "$tmp_dir"
tar -xzf "$versioned_tar" -C "$tmp_dir"

# Move the binary to bin
mkdir -p "${appdir:?}/bin"
extracted_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "syncthing*" | head -n 1)
if [ -d "${appdir:?}/share/syncthing" ]; then
    rm -rf "${appdir:?}/share/syncthing"
fi
mv -f "${extracted_dir:?}" "${appdir:?}/share/syncthing"
if [ -f "${appdir:?}/bin/syncthing" ]; then
    rm -f "${appdir:?}/bin/syncthing"
fi
install -m 755 "${appdir:?}/share/syncthing/syncthing" "${appdir:?}/bin/syncthing"

# Apply initial configuration
if [ ! -f "${appdir:?}/config/config.xml" ]; then
    print_step_header "Installing default config"
    cp -f "${appdir:?}/defaults/config/config.xml" "${appdir:?}/config/config.xml"
    "${appdir:?}/bin/syncthing" generate --no-default-folder --home="${appdir:?}/config/" >"${appdir:?}/logs/syncthing-generate.log" 2>&1 &
    sleep 5
    pkill syncthing
    sed -i 's|name="(none)"|name="Miyoo Mini Plus"|' "${appdir:?}/config/config.xml"
fi

# Install init scripts
print_step_header "Installing init scripts"
mkdir -p "${sysdir:?}/startup"
mkdir -p "${sysdir:?}/checkoff"
install -m 755 "${appdir:?}/bin/start.sh" "${sysdir:?}/startup/syncthing-startup.sh"
install -m 755 "${appdir:?}/bin/stop.sh" "${sysdir:?}/checkoff/syncthing-checkoff.sh"

# Save version & quit
echo "${latest_package_version:?}" >"${appdir:?}/share/syncthing/.current_version"
print_step_header "Syncthing ${latest_package_version:?} installed successfully."
press_any_key_to_exit 0
