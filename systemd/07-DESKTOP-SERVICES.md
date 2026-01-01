# 07 - Desktop Services

Display manager and user-level services for the Hyprland desktop.

## System-Level Desktop Services

### sddm

Simple Desktop Display Manager.

```bash
systemctl status sddm
```

**Purpose:**
- Graphical login screen
- Session selection
- User authentication

**Configuration:**
- `/etc/sddm.conf`
- `/etc/sddm.conf.d/`

```bash
# Restart display manager (logs you out!)
sudo systemctl restart sddm
```

### rtkit-daemon

RealtimeKit - allows real-time scheduling for audio.

```bash
systemctl status rtkit-daemon
```

**Purpose:**
- Grants real-time priority to PipeWire/audio
- Required for low-latency audio

## User-Level Services

User services run under `systemctl --user` and start with your session.

### List User Services

```bash
systemctl --user list-units --type=service
systemctl --user list-units --type=service --state=running
```

### Running User Services

| Service | Purpose |
|---------|---------|
| pipewire | Audio/video server |
| pipewire-pulse | PulseAudio compatibility |
| wireplumber | PipeWire session manager |
| dbus-broker | User D-Bus |
| xdg-desktop-portal | Desktop integration |
| ssh-agent | SSH key agent |

## PipeWire Audio Stack

Modern audio/video framework replacing PulseAudio.

### Services

```bash
systemctl --user status pipewire
systemctl --user status pipewire-pulse
systemctl --user status wireplumber
```

### Architecture

```
pipewire.service          # Core server
    │
    ├── wireplumber.service    # Session/policy manager
    │
    └── pipewire-pulse.service # PulseAudio compatibility
```

### Configuration

```
~/.config/pipewire/
~/.config/wireplumber/
/etc/pipewire/
```

### Commands

```bash
# Check audio
wpctl status

# List sinks/sources
wpctl status | grep -A 20 "Audio"

# Set volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%

# Mute
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Troubleshooting

```bash
# Check for errors
journalctl --user -u pipewire
journalctl --user -u wireplumber

# Verify running
pactl info
```

## D-Bus User Session

```bash
systemctl --user status dbus-broker
```

**Socket:** `/run/user/1000/bus`

Used for desktop notifications, media keys, etc.

## XDG Desktop Portal

Provides sandboxed access to desktop features.

```bash
systemctl --user status xdg-desktop-portal
systemctl --user status xdg-desktop-portal-hyprland
systemctl --user status xdg-document-portal
```

**Purpose:**
- File chooser dialogs for sandboxed apps
- Screen sharing (OBS, Discord, browsers)
- Notifications
- Flatpak integration

### Portal Implementations

For Hyprland/Wayland:
- `xdg-desktop-portal-hyprland` - Screen sharing, screenshots
- `xdg-desktop-portal-gtk` - File chooser, app chooser

**Configuration:** `~/.config/xdg-desktop-portal/portals.conf`

### Startup Configuration (Important)

The portals must be started via **systemd only** - not directly via binaries. The ML4W `xdg.sh` script handles this.

**File:** `~/.config/hypr/scripts/xdg.sh`

```bash
# Stop all portal services first
systemctl --user stop xdg-desktop-portal
systemctl --user stop xdg-desktop-portal-hyprland

# Set environment for portals
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland

# Start via systemd (proper order: backend first, then main portal)
systemctl --user start xdg-desktop-portal-hyprland
sleep 0.1
systemctl --user start xdg-desktop-portal
```

**Warning:** Do NOT start portals directly via `/usr/lib/xdg-desktop-portal*` binaries. This causes DBus name conflicts:
```
[CRITICAL] Couldn't create the dbus connection (Failed to request bus name - File exists)
```

### Troubleshooting Portal Issues

```bash
# Check portal status
systemctl --user status xdg-desktop-portal-hyprland

# If failed, reset and restart
systemctl --user reset-failed xdg-desktop-portal-hyprland
killall xdg-desktop-portal-hyprland xdg-desktop-portal 2>/dev/null
systemctl --user start xdg-desktop-portal-hyprland
systemctl --user start xdg-desktop-portal

# Check logs
journalctl --user -u xdg-desktop-portal-hyprland
```

### Screen Sharing Test

```bash
# Portal should show output names
journalctl --user -u xdg-desktop-portal-hyprland | grep "Found output"
# Should show: Found output name eDP-1, DP-8, etc.
```

## SSH Agent

```bash
systemctl --user status ssh-agent
```

**Purpose:** Caches SSH keys for passwordless authentication

### Configuration

**File:** `~/.config/systemd/user/ssh-agent.service` (if customized)

Or use the system unit.

### Usage

```bash
# Add key
ssh-add ~/.ssh/id_ed25519

# List keys
ssh-add -l

# Remove all keys
ssh-add -D
```

## Flatpak Services

### Session Helper

```bash
systemctl --user status flatpak-session-helper
```

**Purpose:** Manages Flatpak application sessions and permissions.

### Auto-Update Timer (System)

Flatpak apps are updated automatically via systemd timer.

```bash
systemctl status flatpak-update.timer
systemctl list-timers flatpak-update.timer
```

**Schedule:** Runs 2 minutes after boot, then every 24 hours.

**Service files:**

`/etc/systemd/system/flatpak-update.service`
```ini
[Unit]
Description=Update Flatpak
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak update --noninteractive --assumeyes

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/flatpak-update.timer`
```ini
[Unit]
Description=Update Flatpak

[Timer]
OnBootSec=2m
OnActiveSec=2m
OnUnitInactiveSec=24h
OnUnitActiveSec=24h
AccuracySec=1h
RandomizedDelaySec=10m

[Install]
WantedBy=timers.target
```

**Enable:**
```bash
sudo systemctl enable --now flatpak-update.timer
```

**Manual update:**
```bash
flatpak update
```

**Warning:** Unattended updates can grant apps new permissions. Use [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal) to review permissions.

### Installed Applications

```bash
flatpak list --app
```

### Permission Management

```bash
# View app permissions
flatpak info --show-permissions <app-id>

# Override permissions
flatpak override --user --socket=wayland <app-id>

# GUI tool
flatpak run com.github.tchx84.Flatseal
```

## GVFS Services

Virtual filesystem for file managers.

```bash
systemctl --user status gvfs-daemon
systemctl --user status gvfs-udisks2-volume-monitor
systemctl --user status gvfs-metadata
```

**Purpose:**
- Mount network shares
- Trash functionality
- Recent files
- USB drive mounting

## Managing User Services

### Enable/Disable

```bash
# Enable user service
systemctl --user enable <service>

# Disable user service
systemctl --user disable <service>

# Start/stop
systemctl --user start <service>
systemctl --user stop <service>
```

### Linger (Keep Running After Logout)

```bash
# Enable linger for user
sudo loginctl enable-linger $USER

# Check linger status
loginctl show-user $USER | grep Linger
```

### View Logs

```bash
journalctl --user -u <service>
journalctl --user -u <service> -f
```

## Creating User Services

### Service File Location

```
~/.config/systemd/user/
```

### Example Service

**File:** `~/.config/systemd/user/myapp.service`

```ini
[Unit]
Description=My Application

[Service]
ExecStart=/usr/bin/myapp
Restart=on-failure

[Install]
WantedBy=default.target
```

### Enable

```bash
systemctl --user daemon-reload
systemctl --user enable --now myapp
```

## Graphical Target

User services start when reaching `default.target` (graphical session).

```bash
systemctl --user get-default
# graphical-session.target
```

## Quick Reference

```bash
# User services
systemctl --user list-units --type=service
systemctl --user status <service>
systemctl --user restart <service>

# User logs
journalctl --user -u <service>

# Audio
wpctl status
systemctl --user restart pipewire wireplumber

# Display manager
systemctl status sddm

# Create user service
mkdir -p ~/.config/systemd/user
# Create service file
systemctl --user daemon-reload
systemctl --user enable --now <service>
```

## Related

- [02-CORE-SERVICES](./02-CORE-SERVICES.md) - System D-Bus, logind
- [08-HARDWARE](./08-HARDWARE.md) - Audio hardware
- [09-TROUBLESHOOTING](./09-TROUBLESHOOTING.md) - Debugging
