# 07 - Desktop Services

Display manager and user-level services for the Niri desktop.

> Hyprland/ML4W was removed on 2026-02-20. Its services (`hypridle`, `hyprpaper`, `hyprdynamicmonitors`, `xdg-desktop-portal-hyprland`) and their override files are gone.

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
| niri | Compositor session (pulls in `graphical-session.target`) |
| pipewire, pipewire-pulse, wireplumber | Audio/video server, PulseAudio compatibility, session manager |
| dbus-broker | User D-Bus |
| xdg-desktop-portal, xdg-desktop-portal-gtk | Desktop integration (file chooser etc.) |
| gnome-keyring-daemon, gcr-ssh-agent | Secrets and SSH key agent |
| wlsunset | Night light (custom unit in `~/.config/systemd/user/`) |
| protonmail-bridge | Proton Mail IMAP/SMTP bridge |
| psd | Profile-sync-daemon (browser profiles in RAM) |
| openclaw-node | OpenClaw node host (custom unit) |
| gvfs-daemon, gvfs-metadata | Virtual filesystem for file managers |
| flatpak-session-helper | Flatpak sessions |

`blueman` and `nm-applet` start via XDG autostart (`/etc/xdg/autostart/`), shown as `app-…@autostart.service`. `dunst` (notifications) is started by Niri with `-conf ~/.config/niri-setup/dunst/dunstrc`, not as a service.

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

Provides sandboxed access to desktop features (file chooser, screen sharing, Flatpak integration).

```bash
systemctl --user status xdg-desktop-portal xdg-desktop-portal-gtk
```

### Portal Backends for Niri

Niri ships `/usr/share/xdg-desktop-portal/niri-portals.conf`:

```ini
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
```

Installed backends: `xdg-desktop-portal-gnome` (screen sharing, screenshots) and `xdg-desktop-portal-gtk`. Niri implements screencasting through the gnome portal; without it, ScreenCast has no backend. It was missing until 2026-10-12:

```bash
sudo pacman -S xdg-desktop-portal-gnome
systemctl --user restart xdg-desktop-portal
busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | grep ScreenCast
```

Start portals via systemd only, never by running the binaries in `/usr/lib/` directly; that causes D-Bus name conflicts (`Failed to request bus name - File exists`).

### Troubleshooting Portal Issues

```bash
systemctl --user status xdg-desktop-portal
journalctl --user -u xdg-desktop-portal -b
busctl --user list | grep -i portal   # which portal backends are on the bus
```

## SSH Agent

The SSH agent is gcr's, started by socket activation:

```bash
systemctl --user status gcr-ssh-agent.socket
echo $SSH_AUTH_SOCK          # /run/user/1000/gcr/ssh
```

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

## Compositor-Specific Services

Only Niri is installed now, so no compositor conditions are needed. If a second compositor comes back, gate its services with an override:

```ini
# ~/.config/systemd/user/<service>.d/only-niri.conf
[Unit]
ConditionEnvironment=NIRI_SOCKET
```

| Variable | Set By |
|----------|--------|
| `WAYLAND_DISPLAY` | Any Wayland compositor |
| `NIRI_SOCKET` | Niri only |
| `XDG_CURRENT_DESKTOP` | Session (`niri`) |

## Graphical Target

The user manager's default target is `default.target`. Desktop services such as `wlsunset` use `WantedBy=graphical-session.target`, which `niri.service` activates when the session starts.

```bash
systemctl --user get-default
# default.target
systemctl --user list-dependencies graphical-session.target
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
