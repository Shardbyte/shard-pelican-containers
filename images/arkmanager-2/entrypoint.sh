#!/bin/bash
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################

# Pelican Panel ARK Server Entrypoint with arkmanager
# This script uses arkmanager for server management while maintaining Pelican Panel compatibility

set -e

# Default values for common ARK server settings
export STARTUP_DONE="${STARTUP_DONE:-false}"
export ARK_SERVER_MAP="${ARK_SERVER_MAP:-TheIsland}"
export ARK_MAX_PLAYERS="${ARK_MAX_PLAYERS:-70}"
export ARK_SERVER_PASSWORD="${ARK_SERVER_PASSWORD:-}"
export ARK_ADMIN_PASSWORD="${ARK_ADMIN_PASSWORD:-changeme}"
export ARK_SERVER_PVE="${ARK_SERVER_PVE:-false}"
export ARK_ENABLE_RCON="${ARK_ENABLE_RCON:-true}"
export ARK_RCON_PORT="${ARK_RCON_PORT:-27020}"
export ARK_SESSION_NAME="${ARK_SESSION_NAME:-ARK Server}"

# Pelican Panel uses these ports
export GAME_PORT="${SERVER_PORT:-7777}"
export QUERY_PORT="${QUERY_PORT:-27015}"
export RAW_UDP_PORT="${RAW_UDP_PORT:-7778}"

# Internal paths
export ARK_SERVER_ROOT="/home/container/arkserver"
export STEAMCMD_DIR="/home/container/steamcmd"
export ARK_CONFIG_DIR="/home/container/conf"

# Debug function
debug() {
    if [[ "${DEBUG}" == "true" ]]; then
        echo "[DEBUG] $*"
    fi
}

# Print startup information
echo "=========================================="
echo "ARK: Survival Evolved Server with arkmanager"
echo "Pelican Panel Compatible Image"
echo "=========================================="
echo "Server Map: ${ARK_SERVER_MAP}"
echo "Max Players: ${ARK_MAX_PLAYERS}"
echo "PvE Mode: ${ARK_SERVER_PVE}"
echo "Game Port: ${GAME_PORT}"
echo "Query Port: ${QUERY_PORT}"
echo "Raw UDP Port: ${RAW_UDP_PORT}"
echo "RCON Port: ${ARK_RCON_PORT}"
echo "=========================================="

# Setup arkmanager configuration
setup_arkmanager() {
    echo "Setting up arkmanager configuration..."

    # Create arkmanager directories
    mkdir -p /etc/arkmanager/instances
    mkdir -p "${ARK_SERVER_ROOT}"
    mkdir -p "${ARK_SERVER_ROOT}/log"
    mkdir -p "${ARK_SERVER_ROOT}/backup"

    # Copy configuration files
    cp "${ARK_CONFIG_DIR}/arkmanager.cfg" /etc/arkmanager/arkmanager.cfg
    cp "${ARK_CONFIG_DIR}/main.cfg" /etc/arkmanager/instances/main.cfg

    # Set proper permissions
    chmod 644 /etc/arkmanager/arkmanager.cfg
    chmod 644 /etc/arkmanager/instances/main.cfg

    echo "arkmanager configuration completed."
}
# Change to server directory
cd "${ARK_SERVER_ROOT}"

# Setup arkmanager
setup_arkmanager

# Install server if not present
if [[ ! -f "${ARK_SERVER_ROOT}/ShooterGame/Binaries/Linux/ShooterGameServer" ]]; then
    echo "ARK server files not found. Installing via arkmanager..."
    arkmanager install --verbose
    echo "ARK server installation completed."
else
    echo "ARK server files found."
fi

# Update server if requested
if [[ "${UPDATE_ON_START}" == "true" ]]; then
    echo "Updating ARK server via arkmanager..."
    arkmanager update --verbose --force
    echo "Server update completed."
fi

# Install/update mods if specified
if [[ -n "${ARK_MOD_IDS}" ]]; then
    echo "Installing/Updating mods via arkmanager: ${ARK_MOD_IDS}"

    # Convert comma-separated mod IDs to arkmanager format
    IFS=',' read -ra MODS <<< "${ARK_MOD_IDS}"
    for mod_id in "${MODS[@]}"; do
        mod_id=$(echo "${mod_id}" | tr -d ' ')
        if [[ -n "${mod_id}" ]]; then
            echo "Processing mod: ${mod_id}"
            arkmanager installmod "${mod_id}" --verbose
        fi
    done
    echo "Mod installation completed."
fi

# Mark startup as done
export STARTUP_DONE=true

echo "Starting ARK server via arkmanager..."
echo "=========================================="

# Start the ARK server using arkmanager
exec arkmanager start --verbose --no-background
