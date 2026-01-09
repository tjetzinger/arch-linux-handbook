# Wayland Desktop

Documentation for Wayland compositors: Hyprland (primary) and Niri (alternative).

## Contents

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | ML4W dotfiles and component stack |
| [02-CONFIGURATION](./02-CONFIGURATION.md) | Config file structure |
| [03-KEYBINDINGS](./03-KEYBINDINGS.md) | Keyboard shortcuts |
| [04-MONITORS](./04-MONITORS.md) | Display configuration |
| [05-WAYBAR](./05-WAYBAR.md) | Status bar |
| [06-LAUNCHERS](./06-LAUNCHERS.md) | Rofi and menus |
| [07-NOTIFICATIONS](./07-NOTIFICATIONS.md) | SwayNC daemon |
| [08-LOCKSCREEN](./08-LOCKSCREEN.md) | hyprlock and hypridle |
| [09-THEMING](./09-THEMING.md) | Colors and wallpapers |
| [10-TERMINALS](./10-TERMINALS.md) | Warp and Kitty |
| [11-CUSTOMIZATION](./11-CUSTOMIZATION.md) | Adding custom configs |
| [12-KEYRING](./12-KEYRING.md) | GNOME Keyring credential storage |
| [13-REMOTE-ACCESS](./13-REMOTE-ACCESS.md) | VNC remote desktop via SSH tunnel |
| [14-NIRI](./14-NIRI.md) | Niri scrollable-tiling compositor |

## Component Stack

| Component | Choice |
|-----------|--------|
| **Compositor** | Hyprland 0.52.2 |
| **Dotfiles** | ML4W |
| **Bar** | Waybar |
| **Launcher** | Rofi |
| **Notifications** | SwayNC |
| **Lock Screen** | hyprlock |
| **Idle Daemon** | hypridle |
| **Wallpaper** | waypaper + swww |
| **Terminal** | Warp (primary), Kitty (backup) |
| **Dock** | nwg-dock-hyprland |
| **File Manager** | Nautilus |
| **Keyring** | GNOME Keyring |

## Quick Reference

### Essential Keybindings

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal |
| `Super + Q` | Close window |
| `Super + Ctrl + Return` | Application launcher (Rofi) |
| `Super + B` | Browser |
| `Super + E` | File manager |
| `Super + F` | Fullscreen |
| `Super + T` | Toggle floating |
| `Super + V` | Clipboard history |
| `Super + Ctrl + Q` | Logout menu |
| `Super + Print` | Screenshot |

### Quick Commands

```bash
# Reload Hyprland
hyprctl reload

# List windows
hyprctl clients

# List monitors
hyprctl monitors

# Restart Waybar
~/.config/waybar/launch.sh

# Change wallpaper
waypaper
```

## Configuration Locations

```
~/.config/hypr/           # Hyprland config
~/.config/waybar/         # Status bar
~/.config/rofi/           # Application launcher
~/.config/swaync/         # Notifications
~/.config/ml4w/           # ML4W settings and scripts
~/.config/warp-terminal/  # Warp terminal
~/.config/kitty/          # Kitty terminal (backup)
```

## Related

- [../hardware/03-INPUT-DEVICES.md](../hardware/03-INPUT-DEVICES.md) - Input configuration
- [../hardware/04-DISPLAY-GRAPHICS.md](../hardware/04-DISPLAY-GRAPHICS.md) - Display settings
- [../systemd/07-DESKTOP-SERVICES.md](../systemd/07-DESKTOP-SERVICES.md) - User services
