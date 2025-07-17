#!/usr/bin/env bash
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################

# ===============================================================================
# ARK Server Startup Script
# ===============================================================================
# Handles server installation, configuration, mod management, and startup

# Enable strict error handling
set -e

# ===============================================================================
# DEBUG CONFIGURATION
# ===============================================================================

# Enable debug mode if DEBUG environment variable is set
if [[ -n "${DEBUG}" ]] && [[ "${DEBUG,,}" != "false" ]] && [[ "${DEBUG,,}" != "0" ]]; then
    echo "Debug mode enabled - showing all commands"
    set -x
fi

# ===============================================================================
# USER VALIDATION
# ===============================================================================

# Validate that script is running as the correct user
if [[ "$(whoami)" != "${STEAM_USER}" ]]; then
    echo "ERROR: This script must be run as the steam user: ${STEAM_USER}" >&2
    exit 1
fi

# ===============================================================================
# ARKMANAGER VALIDATION
# ===============================================================================

# Validate arkmanager installation
ARKMANAGER="$(command -v arkmanager)"
if [[ ! -x "${ARKMANAGER}" ]]; then
    echo "ERROR: arkmanager is not installed or not executable" >&2
    exit 1
fi

# ===============================================================================
# ARGUMENT PROCESSING
# ===============================================================================

# Build command line arguments based on configuration
args=("$@")

if [[ "${ENABLE_CROSSPLAY:-false}" == "true" ]]; then
    args=('--arkopt,-crossplay' "${args[@]}")
fi

if [[ "${DISABLE_BATTLEYE:-false}" == "true" ]]; then
    args=('--arkopt,-NoBattlEye' "${args[@]}")
fi

# ===============================================================================
# STARTUP BANNER
# ===============================================================================

echo "======================================="
echo ""
echo "# ARK Server - $(date)"
echo "# Image Version: ${IMAGE_VERSION:-unknown}"
echo "# Running as user: ${STEAM_USER} (UID: $(id -u))"
echo "# Arguments: ${args[*]}"
echo "======================================="

# ===============================================================================
# DIRECTORY SETUP
# ===============================================================================

# Change to server volume directory
cd "${ARK_SERVER_VOLUME}"

# Create essential directories
echo "Setting up server directory structure..."

create_missing_dir() {
    for directory in "$@"; do
        [[ -n "${directory}" ]] || continue
        if [[ ! -d "${directory}" ]]; then
            mkdir -p "${directory}"
            echo "Created directory: ${directory}"
        fi
    done
}

create_missing_dir \
    "${ARK_SERVER_VOLUME}/log" \
    "${ARK_SERVER_VOLUME}/backup" \
    "${ARK_SERVER_VOLUME}/staging"

# ===============================================================================
# CONFIGURATION FILE SETUP
# ===============================================================================

# Copy configuration files from templates
copy_missing_file() {
    local source="${1}"
    local destination="${2}"

    if [[ ! -f "${destination}" ]]; then
        # Ensure destination directory exists
        mkdir -p "$(dirname "${destination}")"
        cp -a "${source}" "${destination}"
        echo "Copied ${source} to ${destination}"
    fi
}

copy_missing_file "${TEMPLATE_DIRECTORY}/arkmanager.cfg" "${ARK_TOOLS_DIR}/arkmanager.cfg"
copy_missing_file "${TEMPLATE_DIRECTORY}/arkmanager-user.cfg" "${ARK_TOOLS_DIR}/instances/main.cfg"
copy_missing_file "${TEMPLATE_DIRECTORY}/crontab" "${ARK_SERVER_VOLUME}/crontab"

# ===============================================================================
# SYMBOLIC LINKS SETUP
# ===============================================================================

# Create symbolic links to configuration files
if [[ ! -L "${ARK_SERVER_VOLUME}/Game.ini" ]]; then
    ln -s ./server/ShooterGame/Saved/Config/LinuxServer/Game.ini Game.ini
    echo "Created symlink: Game.ini"
fi

if [[ ! -L "${ARK_SERVER_VOLUME}/GameUserSettings.ini" ]]; then
    ln -s ./server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini GameUserSettings.ini
    echo "Created symlink: GameUserSettings.ini"
fi

# ===============================================================================
# SERVER INSTALLATION
# ===============================================================================

# Install ARK server if not present
if [[ ! -d "${ARK_SERVER_VOLUME}/server" ]] || [[ ! -f "${ARK_SERVER_VOLUME}/server/version.txt" ]]; then
    echo "No game files found. Installing ARK server..."

    # Create game directories
    create_missing_dir \
        "${ARK_SERVER_VOLUME}/server/ShooterGame/Saved/SavedArks" \
        "${ARK_SERVER_VOLUME}/server/ShooterGame/Content/Mods" \
        "${ARK_SERVER_VOLUME}/server/ShooterGame/Binaries/Linux"

    # Create and make executable the server binary placeholder
    touch "${ARK_SERVER_VOLUME}/server/ShooterGame/Binaries/Linux/ShooterGameServer"
    chmod +x "${ARK_SERVER_VOLUME}/server/ShooterGame/Binaries/Linux/ShooterGameServer"

    # Install server files
    ${ARKMANAGER} install --verbose
fi

# ===============================================================================
# CRON SETUP
# ===============================================================================

# Setup cron jobs
if [[ -f "${ARK_SERVER_VOLUME}/crontab" ]]; then
    crontab "${ARK_SERVER_VOLUME}/crontab"
    echo "Cron jobs configured"
fi

# ===============================================================================
# MOD INSTALLATION
# ===============================================================================

# Install mods if specified
if [[ -n "${GAME_MOD_IDS:-}" ]]; then
    echo "Installing mods: ${GAME_MOD_IDS}"

    # Process each mod ID
    for mod_id in ${GAME_MOD_IDS//,/ }; do
        echo "Installing mod: ${mod_id}"

        if [[ -d "${ARK_SERVER_VOLUME}/server/ShooterGame/Content/Mods/${mod_id}" ]]; then
            echo "Mod ${mod_id} already installed"
            continue
        fi

        ${ARKMANAGER} installmod "${mod_id}" --verbose
        echo "Successfully installed mod: ${mod_id}"
    done
fi

# ===============================================================================
# SERVER UPDATES
# ===============================================================================

# Check if server updates should be performed on startup
may_update() {
    if [[ "${UPDATE_ON_START:-false}" != "true" ]]; then
        return 0
    fi

    echo "UPDATE_ON_START is 'true' - checking for updates..."

    # Auto-update server and mods if needed, with backup
    ${ARKMANAGER} update --verbose --update-mods --backup --no-autostart
}

may_update

# ===============================================================================
# SERVER STARTUP
# ===============================================================================

# Start the ARK server
echo "Starting ARK server..."
exec "${ARKMANAGER}" run --verbose "${args[@]}"
