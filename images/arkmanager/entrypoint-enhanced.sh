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

# Create config directory and default files to prevent arkmanager errors
echo "Creating ARK config directory and default files..."
mkdir -p "/home/container/ShooterGame/Saved/Config/LinuxServer"
mkdir -p "/home/container/Saved/Config/LinuxServer"

# Create configs in ShooterGame directory (actual ARK location)
if [[ ! -f "/home/container/ShooterGame/Saved/Config/LinuxServer/Game.ini" ]]; then
    cat > "/home/container/ShooterGame/Saved/Config/LinuxServer/Game.ini" << 'EOF'
[/script/shootergame.shootergamemode]

EOF
    echo "Created default Game.ini in ShooterGame"
fi

if [[ ! -f "/home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" ]]; then
    cat > "/home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" << 'EOF'
[ServerSettings]

EOF
    echo "Created default GameUserSettings.ini in ShooterGame"
fi

# Create symlinks where arkmanager expects them (root Saved directory)
if [[ ! -f "/home/container/Saved/Config/LinuxServer/Game.ini" ]]; then
    ln -sf "/home/container/ShooterGame/Saved/Config/LinuxServer/Game.ini" "/home/container/Saved/Config/LinuxServer/Game.ini"
    echo "Created symlink for Game.ini"
fi

if [[ ! -f "/home/container/Saved/Config/LinuxServer/GameUserSettings.ini" ]]; then
    ln -sf "/home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" "/home/container/Saved/Config/LinuxServer/GameUserSettings.ini"
    echo "Created symlink for GameUserSettings.ini"
fi

# ===============================================================================
# ARK TOOLS INSTALLATION
# ===============================================================================

if command -v arkmanager >/dev/null 2>&1; then
    echo "Ark Server Tools already installed"
else
    echo "Installing Ark Server Tools..."
    curl -sL https://raw.githubusercontent.com/arkmanager/ark-server-tools/master/netinstall.sh | bash -s container --me --perform-user-install --yes-i-really-want-to-perform-a-user-install || true

    # Verify installation and set up symlink
    if [[ -f "/home/container/bin/arkmanager" ]]; then
        ln -sf "/home/container/bin/arkmanager" "/home/container/arkmanager"
        chmod +x /home/container/bin/arkmanager
        echo "Ark Server Tools installed successfully"
    elif [[ -f "/home/container/arkmanager" ]]; then
        chmod +x /home/container/arkmanager
        echo "Ark Server Tools installed successfully"
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

# Clean up unnecessary arkmanager files and directories
echo "Cleaning up unnecessary files and directories..."
rm -f /home/container/.arkmanager.cfg.example 2>/dev/null || true
rm -rf /home/container/.local 2>/dev/null || true
rm -rf /home/container/.config/arkmanager 2>/dev/null || true

# Create arkmanager configuration directories
mkdir -p /home/container/.arkmanager/config /home/container/.arkmanager/libexec /home/container/.arkmanager/data /home/container/logs

# Create single user configuration file with all necessary settings
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
install_bindir="/home/container/bin"
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

# Ensure mods go to the correct location
arkmod_path="/home/container/ShooterGame/Content/Mods"

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

# Debug: Show arkmanager what it's working with
echo "=== ARKMANAGER DEBUG INFO ==="
echo "arkserverroot: ${arkserverroot}"
echo "ARKSERVERROOT: ${ARKSERVERROOT}"
echo "arkstUserCfgFileOverride: ${arkstUserCfgFileOverride}"
echo "Config file exists: $(test -f /home/container/.arkmanager/config/arkmanager.cfg && echo 'YES' || echo 'NO')"
echo "Server binary exists: $(test -f /home/container/ShooterGame/Binaries/Linux/ShooterGameServer && echo 'YES' || echo 'NO')"
echo "Config directory exists: $(test -d /home/container/ShooterGame/Saved/Config/LinuxServer && echo 'YES' || echo 'NO')"
echo "GameUserSettings.ini exists: $(test -f /home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini && echo 'YES' || echo 'NO')"
echo "Full server binary path: /home/container/ShooterGame/Binaries/Linux/ShooterGameServer"
echo "arkmanager expects binary at: ${arkserverroot}/ShooterGame/Binaries/Linux/ShooterGameServer"
echo "arkmanager config path: ${arkserverroot}/${arkserverdir}/Saved/Config/LinuxServer/GameUserSettings.ini"
echo "Expected config exists: $(test -f /home/container/Saved/Config/LinuxServer/GameUserSettings.ini && echo 'YES' || echo 'NO')"
echo "ShooterGame config exists: $(test -f /home/container/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini && echo 'YES' || echo 'NO')"
echo "Listing actual Saved directories:"
ls -la /home/container/Saved/Config/LinuxServer/ 2>/dev/null || echo "Directory not found"
echo "============================="

# Test what arkmanager is actually using for paths
echo "=== ARKMANAGER PATH TEST ==="
echo "Checking for existing arkmanager configs..."
find /home/container -name "*.cfg" -type f 2>/dev/null | head -10 || echo "No existing configs found"
echo "Symlink status: $(ls -la /home/container/.arkmanager.cfg 2>/dev/null || echo 'No symlink found')"
echo "Testing configuration with specific instance..."
./arkmanager printconfig 2>&1 || echo "printconfig failed"
echo "Testing server status..."
./arkmanager status 2>/dev/null | head -5 || echo "status check failed"
echo "=== PATH DEBUGGING ==="
echo "Checking for path duplication issues..."
./arkmanager printconfig 2>/dev/null | grep -E "(GameUserSettings|Game\.ini|arkserverroot)" || echo "No config found"
echo "============================="

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

            # If mod was installed in wrong location, move it to correct location
            if [[ -d "/home/container/Content/Mods/${mod_id}" ]] && [[ ! -d "/home/container/ShooterGame/Content/Mods/${mod_id}" ]]; then
                echo "Moving mod ${mod_id} to correct location..."
                mv "/home/container/Content/Mods/${mod_id}" "/home/container/ShooterGame/Content/Mods/${mod_id}"
                # Clean up empty directory if it exists
                rmdir "/home/container/Content/Mods" 2>/dev/null || true
                rmdir "/home/container/Content" 2>/dev/null || true
            fi
        else
            echo "Mod ${mod_id} already installed"
        fi
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
    ./arkmanager update --verbose --update-mods --backup --no-autostart
}

may_update

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

# Execute startup command
MODIFIED_STARTUP=$(eval echo $(echo ./arkmanager ${STARTUP} --verbose | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

${MODIFIED_STARTUP}

/bin/bash
