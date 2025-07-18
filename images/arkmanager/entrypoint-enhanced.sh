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
    # Run the installation script (ignore exit code, check for actual binary instead)
    curl -sL https://raw.githubusercontent.com/arkmanager/ark-server-tools/master/netinstall.sh | bash -s container --me --perform-user-install --yes-i-really-want-to-perform-a-user-install || true

    # Check if installation actually succeeded by looking for the binary
    if [[ -f "/home/container/bin/arkmanager" ]] || [[ -f "/home/container/arkmanager" ]] || command -v arkmanager >/dev/null 2>&1; then
        echo "Ark Server Tools installation completed successfully"

        # Check if arkmanager was installed in bin directory
        if [[ -f "/home/container/bin/arkmanager" ]]; then
            # Create a symlink in the main directory for easier access
            if [[ ! -f "/home/container/arkmanager" ]] && [[ ! -L "/home/container/arkmanager" ]]; then
                ln -sf "/home/container/bin/arkmanager" "/home/container/arkmanager"
                echo "Created arkmanager symlink for easier access"
            fi
            chmod +x /home/container/bin/arkmanager
            echo "Made arkmanager executable"
        elif [[ -f "/home/container/arkmanager" ]]; then
            chmod +x /home/container/arkmanager
            echo "Made arkmanager executable"
        fi
    else
        echo "Failed to install Ark Server Tools - binary not found after installation" >&2
        exit 1
    fi
fi

# ===============================================================================
# ARKMANAGER CONFIGURATION SETUP
# ===============================================================================

echo "Setting up arkmanager configuration..."

# Ensure proper arkmanager configuration directories exist (using user space instead of /etc)
mkdir -p /home/container/.config/arkmanager/instances
mkdir -p /home/container/logs

# CRITICAL: Create the proper instance configuration file
# This is where arkmanager looks for instance-specific settings
echo "Creating arkmanager instance configuration..."
cat > /home/container/.config/arkmanager/instances/main.cfg << 'EOF'
# ===============================================================================
# ARK Server Manager Instance Configuration - main
# Generated for Pterodactyl container environment
# ===============================================================================

# CRITICAL: Set the ARK server root directory (Pterodactyl container root)
arkserverroot="/home/container"

# Server map and basic settings
serverMap="${MAP:-TheIsland}"
ark_Port=${GAME_CLIENT_PORT:-7778}
ark_QueryPort=${SERVER_LIST_PORT:-27015}
ark_RCONPort=${RCON_PORT:-32330}
ark_MaxPlayers=${MAX_PLAYERS:-50}

# Session configuration
ark_SessionName="${SESSION_NAME:-ARK Server}"
ark_ServerPassword="${SERVER_PASSWORD:-}"

# Mod configuration
ark_GameModIds="${MODS:-}"

# Server behavior
arkAutoUpdateOnStart=${UPDATE_ON_START:-false}
arkBackupPreUpdate=${PRE_UPDATE_BACKUP:-false}

# Alternative save directory (required for Pterodactyl)
ark_AltSaveDirectoryName="SavedArks"

# Backup configuration
arkbackupdir="/home/container/backup"

# Log directory
logdir="/home/container/logs"
EOF

# Create the global configuration file in user space
echo "Creating arkmanager global configuration..."
if [[ -f "/home/container/conf.d/arkmanager.cfg" ]]; then
    cp /home/container/conf.d/arkmanager.cfg /home/container/.config/arkmanager/arkmanager.cfg
else
    echo "Warning: arkmanager.cfg template not found"
fi

# Create user config override to ensure paths are correct
echo "Creating user configuration override..."
cat > /home/container/.arkmanager.cfg << 'EOF'
# ===============================================================================
# ARK Server Manager User Configuration Override
# Force correct paths for Pterodactyl container
# ===============================================================================

# Force the correct server root for this container
arkserverroot="/home/container"

# Instance configuration
defaultinstance="main"
configfile_main="/home/container/.config/arkmanager/instances/main.cfg"

# User-specific settings
steamcmd_user="container"

# Ensure logs go to the right place
logdir="/home/container/logs"
EOF

# Set proper permissions for all configuration files
chown -R container:container /home/container/.config/arkmanager/
chown container:container /home/container/.arkmanager.cfg

# Set arkmanager environment variables to ensure proper paths
unset ARK_ROOT ARK_HOME ARKROOT  # Clear any conflicting environment variables
export arkserverroot="/home/container"
export ARK_SERVER_DIR="/home/container"
export ARK_INSTALL_DIR="/home/container"
export ARKSERVERROOT="/home/container"

# Point arkmanager to user-space configuration files
export arkstGlobalCfgFileOverride="/home/container/.config/arkmanager/arkmanager.cfg"
export arkstUserCfgFileOverride="/home/container/.arkmanager.cfg"

echo "arkmanager configuration setup complete."

# ===============================================================================
# ARKMANAGER DEBUGGING AND VERIFICATION
# ===============================================================================

echo "Verifying arkmanager configuration..."

# Show what configuration files exist
echo "Configuration files:"
echo "  Global config: /home/container/.config/arkmanager/arkmanager.cfg $(test -f /home/container/.config/arkmanager/arkmanager.cfg && echo 'EXISTS' || echo 'MISSING')"
echo "  Instance config: /home/container/.config/arkmanager/instances/main.cfg $(test -f /home/container/.config/arkmanager/instances/main.cfg && echo 'EXISTS' || echo 'MISSING')"
echo "  User config: /home/container/.arkmanager.cfg $(test -f /home/container/.arkmanager.cfg && echo 'EXISTS' || echo 'MISSING')"

# Show environment variables
echo "Environment variables:"
echo "  arkserverroot=${arkserverroot}"
echo "  ARK_SERVER_DIR=${ARK_SERVER_DIR}"
echo "  ARKSERVERROOT=${ARKSERVERROOT}"

# Test arkmanager if available
if command -v arkmanager >/dev/null 2>&1; then
    echo "Testing arkmanager status..."
    arkmanager status main 2>&1 | head -10 || echo "Status command failed"

    echo "Testing arkmanager configuration..."
    arkmanager printconfig main 2>&1 | grep -E "arkserverroot|configfile" || echo "Config test failed"
else
    echo "arkmanager command not found, will test later"
fi

echo "arkmanager configuration and verification complete."

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
    echo "Setting up cron jobs..."
    if crontab "${ARK_SERVER_VOLUME}/crontab" 2>/dev/null; then
        echo "Cron jobs configured successfully"
    else
        echo "WARNING: Could not configure cron jobs (permission denied or cron not available)"
        echo "This is normal in containerized environments - scheduled tasks may need to be handled externally"
        # Create a backup copy for manual setup if needed
        cp "${ARK_SERVER_VOLUME}/crontab" "${ARK_SERVER_VOLUME}/crontab.example" 2>/dev/null || true
        echo "Crontab saved as ${ARK_SERVER_VOLUME}/crontab.example for reference"
    fi
else
    echo "No crontab file found, skipping cron setup"
fi

# ===============================================================================
# SERVER INSTALLATION/UPDATES
# ===============================================================================

cd /home/container || exit 1

# Check if this is a fresh installation (no ShooterGameServer binary)
if [[ ! -f "${ARK_SERVER_VOLUME}/ShooterGame/Binaries/Linux/ShooterGameServer" ]]; then
    echo "No ARK server binary found - server may need installation via Pterodactyl"
    echo "Make sure to run server installation through Pterodactyl panel first"
else
    echo "ARK server binary found - installation looks good"
fi

# Note: Server installation and updates are handled by:
# 1. Pterodactyl's egg installer script (install_script.sh) for initial installation
# 2. arkmanager for ongoing updates and management
echo "Server installation/updates will be managed by arkmanager"

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
