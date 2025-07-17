#!/bin/bash
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################

# ===============================================================================
# Enhanced ARK Manager Entrypoint for Pterodactyl
# Incorporates shard-containers directory structure and configuration management
# ===============================================================================

set -e

# ===============================================================================
# DEBUG CONFIGURATION
# ===============================================================================

if [[ -n "${DEBUG}" ]] && [[ "${DEBUG,,}" != "false" ]] && [[ "${DEBUG,,}" != "0" ]]; then
    echo "Debug mode enabled - showing all commands"
    set -x
fi

# ===============================================================================
# ENVIRONMENT SETUP
# ===============================================================================

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}' 2>/dev/null || echo "127.0.0.1")
export INTERNAL_IP

echo "======================================="
echo "Enhanced ARK Manager for Pterodactyl"
echo "======================================="
echo "Server Volume: ${ARK_SERVER_VOLUME}"
echo "ARK Tools Dir: ${ARK_TOOLS_DIR}"
echo "User: ${USER}"
echo "Internal IP: ${INTERNAL_IP}"
echo "======================================="

# ===============================================================================
# DIRECTORY INITIALIZATION
# ===============================================================================

echo "Setting up directory structure..."

create_missing_dir() {
    for directory in "$@"; do
        [[ -n "${directory}" ]] || continue
        if [[ ! -d "${directory}" ]]; then
            mkdir -p "${directory}"
            echo "Created directory: ${directory}"
        fi
    done
}

# Create essential directories
# Note: Pterodactyl installs to /mnt/server, but runtime is /home/container
create_missing_dir \
    "${ARK_SERVER_VOLUME}/log" \
    "${ARK_SERVER_VOLUME}/backup" \
    "${ARK_SERVER_VOLUME}/staging" \
    "${ARK_TOOLS_DIR}/instances"

# Create game directories if they don't exist (Pterodactyl may have created them)
create_missing_dir \
    "${ARK_SERVER_VOLUME}/ShooterGame/Saved/SavedArks" \
    "${ARK_SERVER_VOLUME}/ShooterGame/Content/Mods" \
    "${ARK_SERVER_VOLUME}/ShooterGame/Binaries/Linux"

# Handle Pterodactyl's steamcmd directory structure
if [[ -d "${ARK_SERVER_VOLUME}/steamcmd" ]]; then
    echo "Found Pterodactyl steamcmd installation"
    # Create symlink for compatibility if needed
    if [[ ! -L "/home/container/steamcmd" ]]; then
        ln -sf "${ARK_SERVER_VOLUME}/steamcmd" "/home/container/steamcmd"
        echo "Created steamcmd symlink for compatibility"
    fi
fi

# ===============================================================================
# ARK TOOLS INSTALLATION
# ===============================================================================

if command -v arkmanager >/dev/null 2>&1; then
    echo "Ark Server Tools already installed, skipping..."
else
    echo "Installing Ark Server Tools..."
    if curl -sL https://raw.githubusercontent.com/arkmanager/ark-server-tools/master/netinstall.sh | bash -s container --me --perform-user-install --yes-i-really-want-to-perform-a-user-install; then
        if cp /home/container/bin/arkmanager /home/container/arkmanager; then
            echo "Ark Server Tools installation completed successfully"

            # Create symlink for easier access
            if [[ -f "/home/container/arkmanager" ]]; then
                chmod +x /home/container/arkmanager
                echo "Made arkmanager executable"
            fi
        else
            echo "Failed to copy arkmanager binary" >&2
            exit 1
        fi
    else
        echo "Failed to install Ark Server Tools" >&2
        exit 1
    fi
fi

# ===============================================================================
# ARKMANAGER CONFIGURATION SETUP
# ===============================================================================

echo "Setting up arkmanager configuration..."

# Initialize ARK tools directory if needed
if [[ ! -f "${ARK_TOOLS_DIR}/arkmanager.cfg" ]]; then
    echo "Initializing ARK tools configuration..."

    # Move default arkmanager config to persistent location if it exists
    if [[ -d "/home/container/.config/arkmanager" ]] && [[ ! -L "/home/container/.config/arkmanager" ]]; then
        echo "Moving arkmanager config to persistent location"
        cp -r "/home/container/.config/arkmanager"/* "${ARK_TOOLS_DIR}/" 2>/dev/null || echo "No existing config to copy"
    fi
fi

# Copy configuration files from templates
copy_missing_file() {
    local source="${1}"
    local destination="${2}"

    if [[ ! -f "${destination}" ]]; then
        mkdir -p "$(dirname "${destination}")"
        if [[ -f "${source}" ]]; then
            cp -a "${source}" "${destination}"
            echo "Copied ${source} to ${destination}"
        else
            echo "WARNING: Template file ${source} not found"
        fi
    fi
}

# Copy configuration templates if they exist
copy_missing_file "${TEMPLATE_DIRECTORY}/arkmanager.cfg" "${ARK_TOOLS_DIR}/arkmanager.cfg"
copy_missing_file "${TEMPLATE_DIRECTORY}/arkmanager-user.cfg" "${ARK_TOOLS_DIR}/instances/main.cfg"
copy_missing_file "${TEMPLATE_DIRECTORY}/crontab" "${ARK_SERVER_VOLUME}/crontab"

# Create symlink for arkmanager configuration
echo "Creating configuration symlinks..."
if [[ -e "/home/container/.config/arkmanager" ]] || [[ -L "/home/container/.config/arkmanager" ]]; then
    rm -rf "/home/container/.config/arkmanager" 2>/dev/null || true
fi
mkdir -p "/home/container/.config"
ln -sf "${ARK_TOOLS_DIR}" "/home/container/.config/arkmanager"

# ===============================================================================
# SYMBOLIC LINKS SETUP
# ===============================================================================

echo "Setting up game configuration symlinks..."

# Create symbolic links to configuration files
if [[ ! -L "${ARK_SERVER_VOLUME}/Game.ini" ]] && [[ -f "${ARK_SERVER_VOLUME}/ShooterGame/Saved/Config/LinuxServer/Game.ini" ]]; then
    ln -sf ./ShooterGame/Saved/Config/LinuxServer/Game.ini "${ARK_SERVER_VOLUME}/Game.ini"
    echo "Created symlink: Game.ini"
fi

if [[ ! -L "${ARK_SERVER_VOLUME}/GameUserSettings.ini" ]] && [[ -f "${ARK_SERVER_VOLUME}/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" ]]; then
    ln -sf ./ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini "${ARK_SERVER_VOLUME}/GameUserSettings.ini"
    echo "Created symlink: GameUserSettings.ini"
fi

# ===============================================================================
# CRON SETUP
# ===============================================================================

# Setup cron jobs if crontab exists
if [[ -f "${ARK_SERVER_VOLUME}/crontab" ]]; then
    crontab "${ARK_SERVER_VOLUME}/crontab"
    echo "Cron jobs configured"
fi

# ===============================================================================
# SERVER INSTALLATION/UPDATES
# ===============================================================================

cd /home/container || exit 1

# Check if this is a fresh installation (no ShooterGameServer binary)
if [[ ! -f "${ARK_SERVER_VOLUME}/ShooterGame/Binaries/Linux/ShooterGameServer" ]]; then
    echo "No ARK server binary found - server may need installation via Pterodactyl"
    echo "Make sure to run server installation through Pterodactyl panel first"
fi

# Auto-update logic (compatible with Pterodactyl's steamcmd structure)
if [[ -z ${AUTO_UPDATE} ]] || [[ "${AUTO_UPDATE}" == "1" ]]; then
    if [[ ! -z ${SRCDS_APPID} ]]; then
        echo "Updating server files..."

        # Use Pterodactyl's steamcmd if available, fallback to container's steamcmd
        STEAMCMD_PATH="./steamcmd/steamcmd.sh"
        if [[ -f "${ARK_SERVER_VOLUME}/steamcmd/steamcmd.sh" ]]; then
            STEAMCMD_PATH="${ARK_SERVER_VOLUME}/steamcmd/steamcmd.sh"
            echo "Using Pterodactyl's steamcmd installation"
        elif [[ -f "./steamcmd/steamcmd.sh" ]]; then
            echo "Using container's steamcmd installation"
        else
            echo "No steamcmd found - skipping update"
        fi

        # SteamCMD update command (adjusted for Pterodactyl compatibility)
        if [[ -f "${STEAMCMD_PATH}" ]]; then
            if [[ "${STEAM_USER}" == "anonymous" ]]; then
                ${STEAMCMD_PATH} +force_install_dir /home/container +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update 1007 +app_update ${SRCDS_APPID} $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) $( [[ -z ${HLDS_GAME} ]] || printf %s "+app_set_config 90 mod ${HLDS_GAME}" )  ${INSTALL_FLAGS} $( [[ "${VALIDATE}" == "1" ]] && printf %s 'validate' ) +quit
            else
                ${STEAMCMD_PATH} +force_install_dir /home/container +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update 1007 +app_update ${SRCDS_APPID} $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) $( [[ -z ${HLDS_GAME} ]] || printf %s "+app_set_config 90 mod ${HLDS_GAME}" ) ${INSTALL_FLAGS} $( [[ "${VALIDATE}" == "1" ]] && printf %s 'validate' ) +quit
            fi
        fi
    else
        echo "No appid set. Starting Server"
    fi
else
    echo "Not updating game server as auto update was set to 0. Starting Server"
fi

# ===============================================================================
# MOD INSTALLATION
# ===============================================================================

# Install mods if specified and arkmanager is available
if [[ -n "${GAME_MOD_IDS:-}" ]] && command -v arkmanager >/dev/null 2>&1; then
    echo "Installing mods: ${GAME_MOD_IDS}"

    for mod_id in ${GAME_MOD_IDS//,/ }; do
        echo "Installing mod: ${mod_id}"

        if [[ -d "${ARK_SERVER_VOLUME}/ShooterGame/Content/Mods/${mod_id}" ]]; then
            echo "Mod ${mod_id} already installed"
            continue
        fi

        ./arkmanager installmod "${mod_id}" --verbose || echo "Failed to install mod ${mod_id}"
    done
fi

# ===============================================================================
# STARTUP EXECUTION
# ===============================================================================

echo "======================================="
echo "Starting ARK Server..."
echo "======================================="

# Execute the startup command
MODIFIED_STARTUP=$(eval echo $(echo ./arkmanager ${STARTUP} --verbose | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

${MODIFIED_STARTUP}

# Keep container alive
/bin/bash
