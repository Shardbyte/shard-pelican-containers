#!/bin/bash
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################

# ===============================================================================
# Enhanced ARK Manager Entrypoint for Pelican
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

echo "Enhanced ARK Manager for Pelican"
echo "Server Volume: ${ARK_SERVER_VOLUME}"

# ===============================================================================
# DIRECTORY INITIALIZATION
# ===============================================================================

echo "Setting up directory structure..."

# Handle Pelican's steamcmd directory structure
if [[ -d "/home/container/steamcmd" ]] || [[ -d "${ARK_SERVER_VOLUME}/steamcmd" ]]; then
    [[ -L "/home/container/steamcmd" ]] || ln -sf "${ARK_SERVER_VOLUME}/steamcmd" "/home/container/steamcmd" 2>/dev/null || true
fi

# Create config directories (server will create .ini files on first run)
echo "Creating ARK config directories..."
mkdir -p "/home/container/ShooterGame/Saved/Config/LinuxServer"
mkdir -p "/home/container/Saved/Config/LinuxServer"

# Create symlinks for config files after server creates them
create_config_symlinks() {
    if [[ -f "/home/container/ShooterGame/Saved/Config/LinuxServer/Game.ini" ]] && [[ ! -f "/home/container/Saved/Config/LinuxServer/Game.ini" ]]; then
        ln -sf "/home/container/ShooterGame/Saved/Config/LinuxServer/Game.ini" "/home/container/Saved/Config/LinuxServer/Game.ini"
        echo "Created symlink for Game.ini"
    fi

    if [[ -f "/home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" ]] && [[ ! -f "/home/container/Saved/Config/LinuxServer/GameUserSettings.ini" ]]; then
        ln -sf "/home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" "/home/container/Saved/Config/LinuxServer/GameUserSettings.ini"
        echo "Created symlink for GameUserSettings.ini"
    fi
}

# ===============================================================================
# ARK TOOLS INSTALLATION
# ===============================================================================

# Create arkmanager directories first (before installation)
echo "Creating arkmanager directory structure..."
mkdir -p /home/container/.arkmanager/bin /home/container/.arkmanager/config /home/container/.arkmanager/libexec /home/container/.arkmanager/data /home/container/logs /home/container/staging

if command -v arkmanager >/dev/null 2>&1; then
    echo "Ark Server Tools already installed"
else
    echo "Installing Ark Server Tools..."
    curl -sL https://raw.githubusercontent.com/arkmanager/ark-server-tools/master/netinstall.sh | bash -s container --me --perform-user-install --yes-i-really-want-to-perform-a-user-install || true

    # Verify installation and set up symlinks
    if [[ -f "/home/container/bin/arkmanager" ]]; then
        # Move existing arkmanager to new location
        mv "/home/container/bin/arkmanager" "/home/container/.arkmanager/bin/arkmanager" 2>/dev/null || true
        chmod +x /home/container/.arkmanager/bin/arkmanager
        ln -sf "/home/container/.arkmanager/bin/arkmanager" "/home/container/arkmanager"
        echo "Ark Server Tools installed and moved to .arkmanager/bin"
    elif [[ -f "/home/container/arkmanager" ]]; then
        # Move existing arkmanager to new location
        mv "/home/container/arkmanager" "/home/container/.arkmanager/bin/arkmanager" 2>/dev/null || true
        chmod +x /home/container/.arkmanager/bin/arkmanager
        ln -sf "/home/container/.arkmanager/bin/arkmanager" "/home/container/arkmanager"
        echo "Ark Server Tools installed and moved to .arkmanager/bin"
    else
        echo "Failed to install Ark Server Tools - binary not found" >&2
        exit 1
    fi
fi

# ===============================================================================
# ARKMANAGER CONFIGURATION SETUP
# ===============================================================================

echo "Setting up arkmanager configuration..."

# Clean up any existing arkmanager configs that might conflict
echo "Cleaning up conflicting configs..."
rm -f /home/container/.arkmanager.cfg.NEW 2>/dev/null || true
rm -f /home/container/.arkmanager.cfg 2>/dev/null || true
rm -f /home/container/.arkmanager.cfg.example 2>/dev/null || true
rm -f /home/container/version.txt 2>/dev/null || true

# Clean up unnecessary arkmanager files and directories
echo "Cleaning up unnecessary files and directories..."
rm -rf /home/container/bin 2>/dev/null || true
rm -rf /home/container/.local 2>/dev/null || true
rm -rf /home/container/.config 2>/dev/null || true
rm -rf /home/container/Content 2>/dev/null || true

# Clean up installation artifacts
echo "Cleaning up installation artifacts..."
rm -f /home/container/Manifest_*.txt 2>/dev/null || true
rm -f /home/container/PackageInfo.bin 2>/dev/null || true
rm -f /home/container/SteamCMDInstall.sh 2>/dev/null || true

# Create single user configuration file with all necessary settings (only if it doesn't exist)
if [[ ! -f "/home/container/.arkmanager/config/arkmanager.cfg" ]]; then
    echo "Creating initial arkmanager configuration..."
    cat > /home/container/.arkmanager/config/arkmanager.cfg << 'EOF'
# ===============================================================================
# INSTANCE CONFIGURATION
# ===============================================================================
defaultinstance="main"
arkSingleInstance="true"

# ===============================================================================
# ARK MANAGER INSTALLATION PATHS
# ===============================================================================
arkstChannel="${BRANCH:-master}"
install_bindir="/home/container/.arkmanager/bin"
install_libexecdir="/home/container/.arkmanager/libexec"
install_datadir="/home/container/.arkmanager/data"

# ===============================================================================
# SERVER PATHS
# ===============================================================================
arkserverroot="/home/container"
arkserverexec="ShooterGame/Binaries/Linux/ShooterGameServer"
arkbackupdir="/home/container/backup"
servicename="arkserv"
arkserverdir="."

# ===============================================================================
# STEAMCMD CONFIGURATION
# ===============================================================================
steamcmdroot="/home/container/steamcmd"
steamcmdexec="steamcmd.sh"
steamcmd_user="container"
steamcmdhome="/home/container"
steamlogin="anonymous"
steamcmd_appinfocache="/home/container/.steam/appcache/appinfo.vdf"
steamcmd_workshoplog="/home/container/.steam/logs/workshop_log.txt"

# ===============================================================================
# STEAM APPLICATION IDS
# ===============================================================================
appid=376030
mod_appid=346110

# ===============================================================================
# SERVER SETTINGS
# ===============================================================================
serverMap="${MAP:-TheIsland}"
ark_MaxPlayers=${MAX_PLAYERS:-20}
ark_SessionName="${SESSION_NAME:-ARK Server}"
ark_ServerPassword="${SERVER_PASSWORD:-}"
ark_ServerAdminPassword="${ADMIN_PASSWORD:-changeMEplease}"
ark_GameModIds="${MODS:-}"
ark_ServerPVE=${SERVER_PVE:-false}
mod_branch=Windows

# ===============================================================================
# NETWORK CONFIGURATION
# ===============================================================================
ark_Port=${GAME_CLIENT_PORT:-7778}
ark_QueryPort=${SERVER_LIST_PORT:-27015}
ark_RCONPort=${RCON_PORT:-27020}
ark_RCONEnabled="true"

# ===============================================================================
# SERVER BEHAVIOR
# ===============================================================================
arkAutoUpdateOnStart=${UPDATE_ON_START:-false}
arkBackupPreUpdate=${PRE_UPDATE_BACKUP:-false}
arkautorestartfile="ShooterGame/Saved/.autorestart"
arkNoPortDecrement="true"

# ===============================================================================
# BACKUP CONFIGURATION
# ===============================================================================
arkbackupcompress="true"
arkwarnminutes="30"
arkprecisewarn="true"
arkBackupPostCommand="${BACKUP_POST_COMMAND:-echo 'Backup Complete!'}"
arkMaxBackupSizeMB="${MAX_BACKUP_SIZE_MB:-500}"

msgWarnUpdateMinutes="This ARK server will shutdown for an update in %d minutes"
msgWarnUpdateSeconds="This ARK server will shutdown for an update in %d seconds"
msgWarnRestartMinutes="This ARK server will shutdown for a restart in %d minutes"
msgWarnRestartSeconds="This ARK server will shutdown for a restart in %d seconds"
msgWarnShutdownMinutes="This ARK server will shutdown in %d minutes"
msgWarnShutdownSeconds="This ARK server will shutdown in %d seconds"

# ===============================================================================
# PATHS AND LOGGING
# ===============================================================================
logdir="/home/container/logs"
arkStagingDir="/home/container/staging"
progressDisplayType="spinner"

# Fix path issues - ensure arkmanager uses correct base paths
arkopt_GameUserSettingsIniFile="/home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"
arkopt_GameIniFile="/home/container/ShooterGame/Saved/Config/LinuxServer/Game.ini"

# Ensure mods go to the correct location and use staging
arkmod_path="/home/container/ShooterGame/Content/Mods"
ark_ModInstallationStagingDir="/home/container/staging"

# Override arkmanager's default mod download behavior
arkmod_downloaddir="/home/container/staging"
arkmod_install_path="/home/container/ShooterGame/Content/Mods"

# ===============================================================================
# CLUSTER CONFIGURATION
# ===============================================================================
#ark_clusterid="${CLUSTER_ID:-}"
#ark_ClusterDirOverride="/home/container/cluster"
#arkflag_NoTransferFromFiltering="false"

#ark_PreventDownloadSurvivors="false"
#ark_PreventDownloadItems="false"
#ark_PreventDownloadDinos="false"
#ark_PreventUploadSurvivors="false"
#ark_PreventUploadItems="false"
#ark_PreventUploadDinos="false"
#ark_noTributeDownloads="false"

# ===============================================================================
# ALTERNATE CONFIGURATIONS
# ===============================================================================
EOF

    # Set proper ownership
    chown container:container /home/container/.arkmanager/config/arkmanager.cfg
    echo "Initial arkmanager configuration created."
else
    echo "Using existing arkmanager configuration."
fi

# Create symlink from old location to new config for compatibility
ln -sf /home/container/.arkmanager/config/arkmanager.cfg /home/container/.arkmanager.cfg

# Set environment variables
export arkserverroot="/home/container"
export arkstUserCfgFileOverride="/home/container/.arkmanager/config/arkmanager.cfg"
export arkSingleInstance="true"
export arkserverdir="."
export ARKSERVERROOT="/home/container"

# Clear any problematic environment variables that might cause path duplication
unset ARK_SERVER_VOLUME 2>/dev/null || true

echo "arkmanager configuration setup complete."

# ===============================================================================
# CRON SETUP
# ===============================================================================

# Setup cron jobs if crontab exists (graceful handling for containers)
[[ ! -f "/home/container/crontab" ]] || crontab "/home/container/crontab" 2>/dev/null || \
    cp "/home/container/crontab" "/home/container/crontab.example" 2>/dev/null

# ===============================================================================
# MOD INSTALLATION
# ===============================================================================

# Install mods if specified
if [[ -n "${MODS:-}" ]] && [[ -f "/home/container/arkmanager" ]]; then
    echo "Installing mods: ${MODS}"
    # Ensure mods directory exists in the correct location
    mkdir -p "/home/container/ShooterGame/Content/Mods"

    for mod_id in ${MODS//,/ }; do
        if [[ ! -d "/home/container/ShooterGame/Content/Mods/${mod_id}" ]]; then
            echo "Installing mod ${mod_id}..."
            ./arkmanager installmod "${mod_id}" --verbose || echo "Failed to install mod ${mod_id}"

            # Immediate cleanup after each mod installation
            if [[ -d "/home/container/Content" ]]; then
                echo "Moving mod from wrong location after installation..."
                if [[ -d "/home/container/Content/Mods/${mod_id}" ]]; then
                    mv "/home/container/Content/Mods/${mod_id}" "/home/container/ShooterGame/Content/Mods/${mod_id}" 2>/dev/null || true
                fi
                rm -rf "/home/container/Content" 2>/dev/null || true
            fi
        else
            echo "Mod ${mod_id} already installed"
        fi
    done

    # Clean up only mod-related files from staging directory
    echo "Cleaning up mod files from staging directory..."
    rm -rf "/home/container/staging/steamapps" 2>/dev/null || true
    rm -rf "/home/container/staging/workshop" 2>/dev/null || true
    rm -f "/home/container/staging"/*.mod 2>/dev/null || true
    rm -f "/home/container/staging"/mod_* 2>/dev/null || true

    # Final cleanup - ensure no Content directory exists
    echo "Final cleanup of Content directory..."
    rm -rf "/home/container/Content" 2>/dev/null || true
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
    ./arkmanager update --verbose --update-mods --backup --no-autostart
}

may_update

# ===============================================================================
# SERVER STATUS MONITORING
# ===============================================================================

# Function to monitor server status and display when online
monitor_server_status() {
    local check_interval=45     # Check every 45 seconds
    local server_online=false

    # Wait for initial startup
    sleep ${check_interval}

    while true; do
        # Run arkmanager status silently and capture output
        local status_output
        status_output=$(./arkmanager status 2>/dev/null || echo "Status check failed")

        # Check if server is online
        if echo "${status_output}" | grep -q "Server online:.*Yes"; then
            if [[ "${server_online}" == "false" ]]; then
                echo "=== SERVER STATUS UPDATE ==="
                echo "${status_output}"
                echo "============================"
                server_online=true
            fi
        else
            server_online=false
        fi

        sleep ${check_interval}
    done
}

# Start server status monitoring in background
monitor_server_status &
STATUS_MONITOR_PID=$!
echo "Server status monitoring started (PID: ${STATUS_MONITOR_PID}) - will display status when server comes online"

# ===============================================================================
# STARTUP EXECUTION
# ===============================================================================

cd /home/container || exit 1

echo "Starting ARK Server..."

# Validate server binary exists
[[ -f "/home/container/ShooterGame/Binaries/Linux/ShooterGameServer" ]] || {
    echo "ERROR: ARK server binary not found at /home/container/ShooterGame/Binaries/Linux/ShooterGameServer"
    echo "Please ensure the server is properly installed via Pelican's egg installer."
    exit 1
}

# Create config symlinks if server has generated config files
create_config_symlinks

# Execute startup command
MODIFIED_STARTUP=$(eval echo $(echo ./arkmanager ${STARTUP} --verbose | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# Build additional command line arguments based on configuration
additional_args=()

if [[ "${ENABLE_CROSSPLAY:-false}" == "true" ]]; then
    additional_args+=('--arkopt,-crossplay')
    echo "Crossplay enabled"
fi

if [[ "${DISABLE_BATTLEYE:-false}" == "true" ]]; then
    additional_args+=('--arkopt,-NoBattlEye')
    echo "BattlEye disabled"
fi

# Add additional arguments to startup command if any exist
if [[ ${#additional_args[@]} -gt 0 ]]; then
    MODIFIED_STARTUP="${MODIFIED_STARTUP} ${additional_args[*]}"
fi

echo ":/home/container$ ${MODIFIED_STARTUP}"

${MODIFIED_STARTUP}

/bin/bash