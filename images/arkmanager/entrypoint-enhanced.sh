#!/bin/bash
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################

# ===============================================================================
# Enhanced ARK: Survival Evolved Entrypoint for Pelican with ARKManager Features
# ===============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions with colors
log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${WHITE}$1${NC}"
}

log_info() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${BLUE}⁂${NC} ${WHITE}$1${NC}"
}

log_success() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${GREEN}✔${NC} ${WHITE}$1${NC}"
}

log_warning() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${YELLOW}⚠${NC} ${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${RED}✘${NC} ${RED}$1${NC}"
}

log_mod() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${PURPLE}◉${NC} ${WHITE}$1${NC}"
}

log_server() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${GREEN}✪${NC} ${WHITE}$1${NC}"
}

log_ark() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${BOLD}${GREEN}🦕${NC} ${WHITE}$1${NC}"
}

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

log_ark "Enhanced ARK: Survival Evolved Server for Pelican"

# ===============================================================================
# DIRECTORY INITIALIZATION
# ===============================================================================

# Handle Pelican's steamcmd directory structure
if [[ -d "/home/container/steamcmd" ]] || [[ -d "${ARK_SERVER_VOLUME}/steamcmd" ]]; then
    [[ -L "/home/container/steamcmd" ]] || ln -sf "${ARK_SERVER_VOLUME}/steamcmd" "/home/container/steamcmd" 2>/dev/null || true
fi

# ===============================================================================
# ARK TOOLS INSTALLATION
# ===============================================================================

# Create arkmanager directories first (before installation)
mkdir -p /home/container/.arkmanager/bin /home/container/.arkmanager/config /home/container/.arkmanager/libexec /home/container/.arkmanager/data /home/container/logs /home/container/staging

if command -v arkmanager >/dev/null 2>&1; then
    log_success "ARK Server Tools already installed"
else
    log_info "Installing ARK Server Tools..."
    curl -sL https://raw.githubusercontent.com/arkmanager/ark-server-tools/master/netinstall.sh | bash -s container --me --perform-user-install --yes-i-really-want-to-perform-a-user-install >/dev/null 2>&1 || true

    # Verify installation and set up symlinks
    if [[ -f "/home/container/bin/arkmanager" ]]; then
        # Move existing arkmanager to new location
        mv "/home/container/bin/arkmanager" "/home/container/.arkmanager/bin/arkmanager" 2>/dev/null || true
        chmod +x /home/container/.arkmanager/bin/arkmanager
        ln -sf "/home/container/.arkmanager/bin/arkmanager" "/home/container/arkmanager"
        log_success "ARK Server Tools installed successfully"
    elif [[ -f "/home/container/arkmanager" ]]; then
        # Move existing arkmanager to new location
        mv "/home/container/arkmanager" "/home/container/.arkmanager/bin/arkmanager" 2>/dev/null || true
        chmod +x /home/container/.arkmanager/bin/arkmanager
        ln -sf "/home/container/.arkmanager/bin/arkmanager" "/home/container/arkmanager"
        log_success "ARK Server Tools installed successfully"
    else
        log_error "Failed to install ARK Server Tools - binary not found"
        exit 1
    fi
fi

# ===============================================================================
# ARKMANAGER CONFIGURATION SETUP
# ===============================================================================

# Clean up any existing arkmanager configs that might conflict
rm -f /home/container/.arkmanager.cfg.NEW 2>/dev/null || true
rm -f /home/container/.arkmanager.cfg 2>/dev/null || true
rm -f /home/container/.arkmanager.cfg.example 2>/dev/null || true
rm -f /home/container/version.txt 2>/dev/null || true

# Clean up unnecessary arkmanager files and directories
rm -rf /home/container/bin 2>/dev/null || true
rm -rf /home/container/.local 2>/dev/null || true
rm -rf /home/container/.config 2>/dev/null || true

# Clean up installation artifacts
rm -f /home/container/Manifest_*.txt 2>/dev/null || true
rm -f /home/container/PackageInfo.bin 2>/dev/null || true
rm -f /home/container/SteamCMDInstall.sh 2>/dev/null || true

# Create single user configuration file with all necessary settings (only if it doesn't exist)
if [[ ! -f "/home/container/.arkmanager/config/arkmanager.cfg" ]]; then
    log_info "Creating ARKManager configuration..."
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
arkserverdir=""
arkserverexec="ShooterGame/Binaries/Linux/ShooterGameServer"
arkbackupdir="/home/container/backup"
servicename="arkserv"

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
mod_branch=Windows

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
arkprecisewarn="true"
arkBackupPostCommand="${BACKUP_POST_COMMAND:-echo 'Backup Complete!'}"
arkMaxBackupSizeMB="${MAX_BACKUP_SIZE_MB:-500}"


arkwarnminutes="5"
arkwarnshutdownminutes="5"
arkwarnrestartminutes="5"
arkwarnupdateminutes="5"

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
    log_success "ARKManager configuration created"
else
    log_info "Using existing ARKManager configuration"
fi

# Create symlink from old location to new config for compatibility
ln -sf /home/container/.arkmanager/config/arkmanager.cfg /home/container/.arkmanager.cfg

# Set environment variables
export arkserverroot="/home/container"
export arkstUserCfgFileOverride="/home/container/.arkmanager/config/arkmanager.cfg"
export arkSingleInstance="true"
export arkserverdir=""
export ARKSERVERROOT="/home/container"

# Create function to allow 'arkmanager' command without ./ prefix
arkmanager() {
    if [[ "$PWD" == "/home/container" ]]; then
        ./arkmanager "$@"
    else
        echo "arkmanager function only works from /home/container directory" >&2
        return 1
    fi
}
export -f arkmanager

# Clear any problematic environment variables that might cause path duplication
unset ARK_SERVER_VOLUME 2>/dev/null || true

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
    log_mod "Installing mods: ${MODS}"
    # Ensure mods directory exists in the correct location
    mkdir -p "/home/container/ShooterGame/Content/Mods"

    for mod_id in ${MODS//,/ }; do
        if [[ ! -d "/home/container/ShooterGame/Content/Mods/${mod_id}" ]]; then
            log_mod "Installing mod ${mod_id}..."
            ./arkmanager installmod "${mod_id}" --verbose || log_warning "Failed to install mod ${mod_id}"

            # Immediate cleanup after each mod installation
            if [[ -d "/home/container/Content" ]]; then
                log_info "Moving mod from wrong location after installation..."
                if [[ -d "/home/container/Content/Mods/${mod_id}" ]]; then
                    mv "/home/container/Content/Mods/${mod_id}" "/home/container/ShooterGame/Content/Mods/${mod_id}" 2>/dev/null || true
                fi
                rm -rf "/home/container/Content" 2>/dev/null || true
            fi
        else
            log_mod "Mod ${mod_id} already installed"
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

    log_info "UPDATE_ON_START is 'true' - checking for updates..."

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
                # Force a newline before status output to separate from prompt
                echo ""
                log_success "=== SERVER STATUS UPDATE ==="
                # Display each line of status output with proper formatting
                while IFS= read -r line; do
                    [[ -n "$line" ]] && log_info "$line"
                done <<< "${status_output}"
                log_success "============================"
                echo ""  # Add blank line after status
                server_online=true
                # Exit monitoring after showing status once
                break
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

# ===============================================================================
# STARTUP EXECUTION
# ===============================================================================

cd /home/container || exit 1

log_server "Starting ARK Server..."

# Validate server binary exists
[[ -f "/home/container/ShooterGame/Binaries/Linux/ShooterGameServer" ]] || {
    log_error "ARK server binary not found at /home/container/ShooterGame/Binaries/Linux/ShooterGameServer"
    log_error "Please ensure the server is properly installed via Pelican's egg installer."
    exit 1
}

# Execute startup command
MODIFIED_STARTUP=$(eval echo $(echo ./arkmanager ${STARTUP} --verbose | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# Build additional command line arguments based on configuration
additional_args=()

if [[ "${ENABLE_CROSSPLAY:-false}" == "true" ]]; then
    additional_args+=('--arkopt,-crossplay')
    log_info "Crossplay enabled"
fi

if [[ "${DISABLE_BATTLEYE:-false}" == "true" ]]; then
    additional_args+=('--arkopt,-NoBattlEye')
    log_info "BattlEye disabled"
fi

# Add additional arguments to startup command if any exist
if [[ ${#additional_args[@]} -gt 0 ]]; then
    MODIFIED_STARTUP="${MODIFIED_STARTUP} ${additional_args[*]}"
fi

log_server "Starting server with command: ${MODIFIED_STARTUP}"

# Execute the startup command and handle exit properly
${MODIFIED_STARTUP}

/bin/bash