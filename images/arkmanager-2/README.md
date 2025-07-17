<!--
#
#
###########################
#                         #
#  Saint @ Shardbyte.com  #
#                         #
###########################
# Author: Shardbyte (Saint)
#
#
-->

<div align="center">
  <img src="https://raw.githubusercontent.com/Shardbyte/Shardbyte/main/img/logo-shardbyte-master-light.webp" alt="Shardbyte Logo" width="100"/>

  # 🐳 ARK: Survival Evolved Server

  **Production-ready containerized ARK server with ARK-Server-Tools**

  [![Build Status](https://img.shields.io/github/actions/workflow/status/shardbyte/shard-containers/build.yml)](https://hub.docker.com/r/shardbyte/docker-ark)
  [![Docker Pulls](https://img.shields.io/docker/pulls/shardbyte/docker-ark.svg)](https://hub.docker.com/r/shardbyte/docker-ark)
  [![Image Size](https://img.shields.io/docker/image-size/shardbyte/docker-ark)](https://hub.docker.com/r/shardbyte/docker-ark)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

  *Automated ARK server management for public and private gaming sessions*
</div>

---

## 📋 What is ARK: Survival Evolved?

ARK: Survival Evolved is a multiplayer survival game where players must survive on an island filled with dinosaurs and other prehistoric creatures. This containerized server solution provides automated server management using [ARK-Server-Tools](https://github.com/arkmanager/ark-server-tools), enabling easy deployment and maintenance of ARK servers for both public and private gaming sessions.

## ✨ Features

- 🔒 **Security-First**: Non-root user execution with proper permission handling
- 🎮 **ARK-Server-Tools**: Full integration with the community-standard management tools
- 🔧 **Mod Support**: Easy installation and management of Steam Workshop mods
- 📦 **Automated Management**: Automatic updates, backups, and server maintenance
- 🌐 **Crossplay Ready**: Support for Epic Games Store crossplay functionality
- 📊 **Monitoring**: Built-in health checks and structured logging
- 🛡️ **Hardened**: Security-focused container design with minimal attack surface

## 🏗️ Image Details

- **Base Image**: `shardbyte/steamcmd:latest`
- **Architecture**: `linux/amd64`
- **User**: `steam` (UID: 1000) via gosu
- **ARK Data**: `/opt/ark`
- **Config**: `/opt/arkmanager`
- **Size**: ~200MB (does not include ARK server files)

## ⚠️ Important Notice

### Windows / WSL Users
**Mount container volumes directly inside WSL's filesystem.** Mounting volumes on Windows-managed filesystems can cause extremely slow performance or installation failures.

## 🚀 Quick Start

### Basic Usage

```bash
# Quick start with default settings
docker run -d \
  --name="ark_server" \
  --restart=unless-stopped \
  -v "${HOME}/ark-server:/opt/ark" \
  -e SESSION_NAME="My ARK Server" \
  -e ADMIN_PASSWORD="MySecurePassword" \
  -p 7777:7777/udp \
  -p 7778:7778/udp \
  -p 27020:27020/tcp \
  -p 27015:27015/udp \
  shardbyte/docker-ark:latest
```

### Production Deployment

```yaml
services:
  ark_server:
    image: 'shardbyte/docker-ark:latest'
    container_name: ark_server
    restart: unless-stopped
    environment:
      SESSION_NAME: "My Production ARK Server"
      SERVER_MAP: "TheIsland"
      ADMIN_PASSWORD: "MySecurePassword"
      MAX_PLAYERS: 50
      UPDATE_ON_START: true
      BACKUP_ON_STOP: true
      ARK_SERVER_VOLUME: "/opt/ark"
    volumes:
      - './ark-data:/opt/ark'
      - './ark-config:/opt/arkmanager'
    ports:
      - "7777:7777/udp"
      - "7778:7778/udp"
      - "27020:27020/tcp"
      - "27015:27015/udp"
    networks:
      - ark_network

networks:
  ark_network:
    driver: bridge
```

## 🔧 Configuration

### Environment Variables

| Variable | Default Value | Explanation |
|:-----------------:|:----------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------:|
| `STEAM_LOGIN` | `anonymous` | Steam login username (use for non-anonymous DLCs/mods) |
| `SESSION_NAME` | `Dockerized ARK Server` | The name of your ARK session which is visible in game when searching for servers |
| `SERVER_MAP` | `TheIsland` | Desired map you want to play |
| `SERVER_PASSWORD` | `theDEFAULTpassword` | Server password which is required to join your session (use empty string to disable password authentication) |
| `SERVER_PVE` | `false` | Enable PVE mode |
| `ADMIN_PASSWORD` | `changeMEplease` | Admin password to access the admin console of ARK |
| `MAX_PLAYERS` | `20` | Maximum number of players to join your session |
| `UPDATE_ON_START` | `false` | Whether you want to update the ARK server upon startup or not |
| `BACKUP_ON_STOP` | `false` | Create a backup before gracefully stopping the ARK server |
| `BACKUP_POST_COMMAND` | `echo 'Backup Complete!'` | Command to run after backup |
| `PRE_UPDATE_BACKUP` | `true` | Create a backup before updating ARK server |
| `WARN_ON_STOP` | `true` | Broadcast a warning upon graceful shutdown |
| `ENABLE_CROSSPLAY` | `false` | Enable crossplay. When enabled, BattlEye should be disabled as it likes to disconnect Epic players |
| `DISABLE_BATTLEYE` | `false` | Disable BattlEye protection |
| `ARK_SERVER_VOLUME` | `/opt/ark` | Path where the server files are stored (Only change if you know what you're doing)|
| `GAME_MOD_IDS` | `empty` | Additional game mods you want to install, separated by comma (e.g. `GAME_MOD_IDS=487516323,487516324,487516325`) |
| `GAME_CLIENT_PORT` | `7777` | Exposed game client port |
| `UDP_SOCKET_PORT` | `7778` | Raw UDP socket port (always Game client port +1) |
| `RCON_PORT` | `27020` | Exposed RCON port |
| `SERVER_LIST_PORT` | `27015` | Exposed server list port |

### Server Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| `7777` | UDP | Game client connections |
| `7778` | UDP | Raw UDP socket (Game port + 1) |
| `27020` | TCP | RCON management |
| `27015` | UDP | Steam server list |

### Directory Structure

```
/opt/ark/                    # ARK server data (ARK_SERVER_VOLUME)
├── server/                  # ARK server installation
│   └── ShooterGame/
│       ├── Binaries/Linux/  # Server executable
│       ├── Content/         # Game content and mods
│       └── Saved/           # Save files and configs
├── log/                     # Server logs
├── backup/                  # Automatic backups
└── staging/                 # Update staging area

/opt/arkmanager/             # ARK manager configuration
├── arkmanager.cfg           # Main configuration
├── instances/               # Instance configurations
│   └── main.cfg            # Default instance config
└── ...                     # Additional ARK-Server-Tools files
```

## 🎮 Examples

### Docker Run

I personally prefer `docker-compose` but for those of you who want to run their own ARK server without any "zip and zap", here you go:

```bash
# Basic ARK server with custom settings
docker run -d \
  --name="ark_server" \
  --restart=unless-stopped \
  -v "${HOME}/ark-server:/opt/ark" \
  -e SESSION_NAME="Dockerized ARK Server" \
  -e ADMIN_PASSWORD="changeMEplease" \
  -e SERVER_MAP="Ragnarok" \
  -e MAX_PLAYERS="50" \
  -p 7777:7777/udp \
  -p 7778:7778/udp \
  -p 27020:27020/tcp \
  -p 27015:27015/udp \
  shardbyte/docker-ark:latest
```

### Docker Compose

In order to startup your own ARK server with `docker-compose` - which is the recommended approach - you may adapt the following example:

```yaml
#################################################
# Copyright (c) Shardbyte. All Rights Reserved. #
# SPDX-License-Identifier: MIT                  #
#################################################
# Shardbyte ARK Server | docker-compose.yml

services:
  ark_server:
    image: 'shardbyte/docker-ark:latest'
    container_name: ark_server
    restart: unless-stopped
    environment:
      # === Steam Authentication (uncomment if needed for DLCs/private mods)
      # STEAM_LOGIN: ${STEAM_LOGIN}

      # === Server Identity
      SESSION_NAME: ${SESSION_NAME:-"Dockerized ARK Server"}
      SERVER_MAP: ${SERVER_MAP:-"TheIsland"}
      SERVER_PASSWORD: ${SERVER_PASSWORD:-""}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD:-"changeMEplease"}

      # === Server Settings
      SERVER_PVE: ${SERVER_PVE:-"false"}
      MAX_PLAYERS: ${MAX_PLAYERS:-"20"}
      ENABLE_CROSSPLAY: ${ENABLE_CROSSPLAY:-"false"}
      DISABLE_BATTLEYE: ${DISABLE_BATTLEYE:-"false"}

      # === Automation
      UPDATE_ON_START: ${UPDATE_ON_START:-"false"}
      BACKUP_ON_STOP: ${BACKUP_ON_STOP:-"false"}
      BACKUP_POST_COMMAND: ${BACKUP_POST_COMMAND:-"echo 'Backup Complete!'"}
      PRE_UPDATE_BACKUP: ${PRE_UPDATE_BACKUP:-"true"}
      WARN_ON_STOP: ${WARN_ON_STOP:-"true"}

      # === System Configuration (Advanced)
      CLUSTER_ID: ${CLUSTER_ID:-"im_a_random_cluster_id"}
      ARK_SERVER_VOLUME: "/opt/ark"

      # === Mods and Networking
      GAME_MOD_IDS: ${GAME_MOD_IDS:-""}
      GAME_CLIENT_PORT: ${GAME_CLIENT_PORT:-"7777"}
      UDP_SOCKET_PORT: ${UDP_SOCKET_PORT:-"7778"}
      RCON_PORT: ${RCON_PORT:-"27020"}
      SERVER_LIST_PORT: ${SERVER_LIST_PORT:-"27015"}

    volumes:
      # === Steam Session (uncomment if using authenticated Steam login)
      # - '${STEAM_SESSION_VOLUME}:/home/steam/Steam'

      # === ARK Server Data
      - '${ARK_DATA_PATH:-./ark-data}:/opt/ark'

      # === ARK Manager Configuration
      - '${ARK_CONFIG_PATH:-./ark-config}:/opt/arkmanager'

      # === Cluster data
      - '${ARK_CLUSTER_PATH:-./ark-cluster}:/opt/cluster'
    networks:
      - ark_network

    ports:
      # Game client connections
      - "${GAME_CLIENT_PORT:-7777}:${GAME_CLIENT_PORT:-7777}/udp"
      # Raw UDP socket (always Game port + 1)
      - "${UDP_SOCKET_PORT:-7778}:${UDP_SOCKET_PORT:-7778}/udp"
      # RCON management
      - "${RCON_PORT:-27020}:${RCON_PORT:-27020}/tcp"
      # Steam server list
      - "${SERVER_LIST_PORT:-27015}:${SERVER_LIST_PORT:-27015}/udp"

networks:
  ark_network:
    driver: bridge
```

### Environment File (.env)

Create a `.env` file to customize your server:

```env
# Server Identity
SESSION_NAME=My Awesome ARK Server
SERVER_MAP=TheIsland
SERVER_PASSWORD=
ADMIN_PASSWORD=MySecurePassword123

# Player Settings
SERVER_PVE=false
MAX_PLAYERS=50

# Automation
UPDATE_ON_START=true
BACKUP_ON_STOP=true

# Mods (comma-separated Steam Workshop IDs)
GAME_MOD_IDS=731604991,899987403

# Paths
ARK_DATA_PATH=./ark-data
ARK_CONFIG_PATH=./ark-config
ARK_CLUSTER_PATH=./ark-cluster
```

Start your server:

```bash
docker-compose up -d
```

## 🔧 Server Management

### ARK-Server-Tools Commands

The container includes full ARK-Server-Tools functionality:

```bash
# Check server status
docker exec -u steam ark_server arkmanager status

# Update server and mods
docker exec -u steam ark_server arkmanager update --force --update-mods

# Install specific mods
docker exec -u steam ark_server arkmanager installmod 731604991

# Create backup
docker exec -u steam ark_server arkmanager backup

# Broadcast message
docker exec -u steam ark_server arkmanager notify "Server restart in 10 minutes"

# View logs
docker exec -u steam ark_server arkmanager logs
```

### Configuration Files

Access and modify server configuration directly:

The main config files are located at the following path in the container:

- `/opt/ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini`
- `/opt/ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini`

```bash
# Edit main game settings
nano ark-data/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini

# Edit advanced game settings
nano ark-data/server/ShooterGame/Saved/Config/LinuxServer/Game.ini

# Edit ARK manager configuration
nano ark-config/arkmanager.cfg

# Edit instance-specific settings
nano ark-config/instances/main.cfg
```

For complete configuration reference, see the [ARK-Server-Tools documentation](https://github.com/arkmanager/ark-server-tools#configuration).

## 🔄 Automation

### Automated Backups

Configure automatic backups with cron jobs:

```bash
# Edit the crontab file in your ARK data directory
nano ark-data/crontab
```

Add scheduled tasks:

```cron
# Daily backup at 3 AM
0 3 * * * arkmanager backup >> /opt/ark/log/crontab.log 2>&1

# Weekly server update (Sundays at 4 AM)
0 4 * * 0 arkmanager update --warn --update-mods >> /opt/ark/log/crontab.log 2>&1

# Restart server every 12 hours with warning
0 */12 * * * arkmanager restart --warn >> /opt/ark/log/crontab.log 2>&1
```

Restart the container to apply cron jobs:

```bash
docker restart ark_server
```

## 🔐 Steam Authentication

### For DLCs and Private Mods

Some content requires Steam authentication. Set up a persistent Steam session:

#### 1. Create Steam Session

```bash
# Create Steam session directory
mkdir -p steam-session
chown 1000:1000 steam-session

# Login to Steam and create session
docker run --rm -it \
  --entrypoint /home/steam/steamcmd/steamcmd.sh \
  -u steam \
  -v "$(pwd)/steam-session:/home/steam/Steam" \
  shardbyte/steamcmd:latest \
  '+login YOUR_STEAM_USERNAME "YOUR_STEAM_PASSWORD"'
```

#### 2. Configure ARK Server

Update your `docker-compose.yml`:

```yaml
environment:
  STEAM_LOGIN: "YOUR_STEAM_USERNAME"
volumes:
  - './steam-session:/home/steam/Steam:rw'
  # ... other volumes
```

## 🛡️ Security

### Security Features

- **Non-root execution**: ARK server runs as `steam` user (UID: 1000)
- **Permission handling**: Root entrypoint properly sets permissions then drops privileges
- **Isolated environment**: Server contained within designated directories
- **Minimal attack surface**: Based on hardened SteamCMD image

### Best Practices

1. **Change default passwords**: Always set strong `ADMIN_PASSWORD`
2. **Use environment files**: Store sensitive data in `.env` files
3. **Regular updates**: Enable `UPDATE_ON_START` for security patches
4. **Backup strategy**: Configure automated backups with `BACKUP_ON_STOP`
5. **Network isolation**: Use custom Docker networks
6. **Resource limits**: Set appropriate CPU and memory limits

## 🔨 Development

### Building the Image

```bash
# Clone the repository
git clone https://github.com/Shardbyte/shard-containers.git
cd shard-containers/images/docker-ark

# Build the image
docker build -t shardbyte/docker-ark:latest .

# Test the build
docker run --rm shardbyte/docker-ark:latest arkmanager --version
```

### Testing

```bash
# Test basic functionality
docker run --rm \
  -e SESSION_NAME="Test Server" \
  -e ADMIN_PASSWORD="test123" \
  shardbyte/docker-ark:latest \
  bash -c 'arkmanager status'
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly with a real ARK server deployment
4. Commit your changes
5. Push to the branch
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.

## 🔗 Links

- **Docker Hub**: [shardbyte/docker-ark](https://hub.docker.com/r/shardbyte/docker-ark)
- **Source Code**: [GitHub Repository](https://github.com/Shardbyte/shard-containers)
- **ARK-Server-Tools**: [Official Documentation](https://github.com/arkmanager/ark-server-tools)
- **Website**: [shardbyte.com](https://shardbyte.com)
- **Contact**: containers@shardbyte.com

## 💡 Acknowledgments

- Thanks to the [ARK-Server-Tools](https://github.com/arkmanager/ark-server-tools) maintainers
- Wildcard for creating ARK: Survival Evolved
- The ARK server hosting community for feedback and testing

---

<div align="center">
  <sub>Part of the <a href="https://github.com/Shardbyte/shard-containers">Shard Containers</a> collection</sub>
</div>
