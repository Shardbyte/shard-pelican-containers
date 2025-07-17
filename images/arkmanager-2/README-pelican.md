# ARK: Survival Evolved Server for Pelican Panel

This Docker image provides an ARK: Survival Evolved dedicated server using arkmanager, specifically designed for use with Pelican Panel (formerly Pterodactyl Panel).

## Features

- **Pelican Panel Compatible**: Designed to work seamlessly with Pelican Panel's server management
- **arkmanager Integration**: Uses the popular arkmanager tool for robust server management
- **Automatic Server Installation**: Downloads and installs ARK server files on first run
- **Mod Support**: Automatic mod installation and management via Steam Workshop through arkmanager
- **Configurable**: Extensive environment variable configuration
- **Signal Handling**: Proper shutdown handling for graceful server stops
- **Crossplay Support**: Optional Epic Games crossplay functionality

## Environment Variables

### Required Variables
- `SERVER_PORT`: Game server port (default: 7777)
- `QUERY_PORT`: Query port for server browser (default: 27015)
- `RAW_UDP_PORT`: Raw UDP socket port (default: 7778)
- `ARK_RCON_PORT`: RCON port for remote administration (default: 27020)

### Server Configuration
- `ARK_SERVER_MAP`: Server map name (default: TheIsland)
- `ARK_MAX_PLAYERS`: Maximum number of players (default: 70)
- `ARK_SESSION_NAME`: Server name displayed in browser (default: ARK Server)
- `ARK_SERVER_PASSWORD`: Server password (optional)
- `ARK_ADMIN_PASSWORD`: Admin password for RCON (default: changeme)
- `ARK_SERVER_PVE`: Enable PvE mode (default: false)

### Advanced Options
- `ARK_MOD_IDS`: Comma-separated list of Steam Workshop mod IDs
- `ARK_ENABLE_CROSSPLAY`: Enable Epic Games crossplay (default: false)
- `ARK_DISABLE_BATTLEYE`: Disable BattlEye anti-cheat (default: false)
- `ARK_EXTRA_ARGS`: Additional command line arguments
- `UPDATE_ON_START`: Update server on startup (default: false)
- `DEBUG`: Enable debug logging (default: false)

## Ports

The following ports need to be configured in Pelican Panel:

- **Game Port**: 7777/UDP (configurable via `SERVER_PORT`)
- **Query Port**: 27015/UDP (configurable via `QUERY_PORT`)
- **Raw UDP Port**: 7778/UDP (configurable via `RAW_UDP_PORT`)
- **RCON Port**: 27020/TCP (configurable via `ARK_RCON_PORT`)

## Pelican Panel Egg

A compatible Pelican Panel egg configuration is included in the `deploy/` directory. This egg provides:

- Proper startup command configuration
- Environment variable definitions
- Port allocations
- Installation script
- Configuration file management

## File Structure

The server files are organized as follows:

```
/home/container/
├── arkserver/                    # ARK server installation
│   ├── ShooterGame/
│   │   ├── Binaries/Linux/       # Server executables
│   │   ├── Saved/               # Save files and configs
│   │   └── Content/Mods/        # Installed mods
├── steamcmd/                    # SteamCMD installation
└── entrypoint.sh               # Container entrypoint
```

## Configuration Files

ARK server configuration files are located in:
- `arkserver/ShooterGame/Saved/Config/LinuxServer/Game.ini`
- `arkserver/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini`

These files can be edited through Pelican Panel's file manager.

## Building the Image

```bash
docker build -t shardbyte/pelican-ark:latest .
```

## Usage with Pelican Panel

1. Import the provided egg configuration
2. Create a new server using the egg
3. Configure the environment variables as needed
4. Start the server

The container will automatically:
- Download and install ARK server files
- Install any specified mods
- Generate default configuration files
- Start the server with the configured settings

## Troubleshooting

### Server Won't Start
- Check that all required ports are properly allocated
- Verify that the `ARK_ADMIN_PASSWORD` is set
- Check the server console for error messages

### Mods Not Loading
- Ensure `ARK_MOD_IDS` contains valid Steam Workshop IDs
- Check that mods are compatible with the current ARK version
- Allow extra time for initial mod downloads

### Connection Issues
- Verify firewall settings allow traffic on configured ports
- Check that `SERVER_PORT` matches the allocated port in Pelican Panel
- Ensure crossplay settings match client requirements

## Support

For issues specific to this container image, please open an issue on the [Shardbyte GitHub repository](https://github.com/Shardbyte/shard-pelican-containers).

For ARK server configuration help, consult the [official ARK wiki](https://ark.fandom.com/wiki/Server_configuration).
