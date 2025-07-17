# Enhanced ARK Manager for Pterodactyl

This enhanced version of the ARK Manager container for Pterodactyl incorporates the robust directory structure and configuration management from the shard-containers project.

## Features

### 🏗️ **Enhanced Directory Structure**
- Proper directory layout with organized folders for logs, backups, and staging
- Persistent configuration directory (`.arkmanager`) for settings
- Symbolic links for easy access to game configuration files

### ⚙️ **Advanced Configuration Management**
- Template-based configuration system
- Automatic configuration file copying and setup
- Environment variable substitution in config files
- Persistent arkmanager settings across container restarts

### 🔧 **Improved Functionality**
- Automatic mod installation support
- Cron job configuration for scheduled tasks
- Better error handling and logging
- Debug mode support

## Directory Structure

```
/home/container/
├── .arkmanager/              # Persistent arkmanager configuration
│   ├── arkmanager.cfg        # Main arkmanager configuration
│   └── instances/
│       └── main.cfg          # Server instance configuration
├── log/                      # Server logs
├── backup/                   # Backup files
├── staging/                  # Staging area for updates
├── ShooterGame/              # ARK server files
├── Game.ini -> ./ShooterGame/Saved/Config/LinuxServer/Game.ini
├── GameUserSettings.ini -> ./ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
└── crontab                   # Cron job configuration
```

## Environment Variables

### Core Settings
- `SESSION_NAME`: Server name (default: "Pterodactyl ARK Server")
- `SERVER_MAP`: Map to use (default: "TheIsland")
- `SERVER_PASSWORD`: Server password (default: empty)
- `ADMIN_PASSWORD`: Admin password (default: "changeMEplease")
- `MAX_PLAYERS`: Maximum players (default: "20")
- `SERVER_PVE`: Enable PVE mode (default: "false")

### Advanced Settings
- `GAME_MOD_IDS`: Comma-separated mod IDs to install
- `UPDATE_ON_START`: Auto-update on startup (default: "false")
- `PRE_UPDATE_BACKUP`: Backup before updates (default: "true")
- `DEBUG`: Enable debug logging (default: "false")

## Usage with Pterodactyl

### Installation Workflow
1. **Install the server files first** via Pterodactyl's installation process
   - This uses the `install_script.sh` to download ARK server files
   - Creates the proper steamcmd and Engine directory structure

2. **Build the enhanced container:**
   ```bash
   docker build -f Dockerfile.enhanced -t arkmanager-enhanced .
   ```

3. **Configure in Pterodactyl:**
   - Use `arkmanager-enhanced` as your Docker image
   - Set the startup command: `run --verbose`
   - Configure environment variables as needed
   - **Important**: Run server installation through Pterodactyl panel first

4. **Install mods:**
   Set `GAME_MOD_IDS=123456,789012` to automatically install mods

### Pterodactyl Compatibility
This enhanced container is designed to work with Pterodactyl's installation process:
- Recognizes Pterodactyl's `/mnt/server` → `/home/container` mapping
- Compatible with the steamcmd structure created by `install_script.sh`
- Handles the Engine/Binaries directory structure properly
- Works with Pterodactyl's Steam SDK setup

## Configuration Files

### `/conf.d/arkmanager.cfg`
Main arkmanager system configuration. Contains paths, SteamCMD settings, and system-level options.

### `/conf.d/arkmanager-user.cfg`
Server instance configuration. Contains server-specific settings like name, password, map, etc.

### `/conf.d/crontab`
Cron job configuration for scheduled tasks like automatic backups or updates.

## Benefits over Standard Pelican Container

1. **Persistent Configuration**: Settings survive container restarts
2. **Better Organization**: Clean directory structure for logs, backups, configs
3. **Advanced Features**: Automatic mod installation, cron jobs, debugging
4. **Template System**: Easy configuration management through environment variables
5. **Symbolic Links**: Direct access to game configuration files
6. **Error Handling**: Better error reporting and recovery

## Migration from Standard Container

If migrating from the standard pelican container:

1. Your existing server files will remain in `/home/container/`
2. Configuration will be automatically migrated to `.arkmanager/`
3. Symbolic links will be created for `Game.ini` and `GameUserSettings.ini`
4. No data loss - everything is backward compatible

## Debugging

Enable debug mode by setting `DEBUG=true` to see detailed command execution and troubleshooting information.

## Support

This enhanced container maintains full compatibility with Pterodactyl while adding the robust features from shard-containers. It's designed to be a drop-in replacement with significant functionality improvements.
