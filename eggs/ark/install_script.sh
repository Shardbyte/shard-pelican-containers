#!/bin/bash
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################
# steamcmd base installation script
# Server Files: /mnt/server
# Image to install with is 'ghcr.io/shardbyte/installers:debian'

if [ "${STEAM_USER}" == "" ]; then
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
fi

cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd

mkdir -p /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
tar -xzvf steamcmd.tar.gz -C /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
mkdir -p /mnt/server/steamapps
cd /mnt/server/steamcmd

chown -R root:root /mnt
export HOME=/mnt/server

./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server +app_update ${SRCDS_APPID} $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) ${EXTRA_FLAGS} validate +quit

mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

cd /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
ln -sf ../../../../../Steam/steamapps steamapps
cd /mnt/server

echo "-----------------------------------------"
echo "Installation completed..."
echo "-----------------------------------------"