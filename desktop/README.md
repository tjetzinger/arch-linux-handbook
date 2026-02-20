# Wayland Desktop

Documentation for the Niri scrollable-tiling Wayland compositor.

> Hyprland + ML4W were removed on 2026-02-20. Archive at `~/backup/ml4w-hyprland-archive-20260220.tar.gz`.

## Contents

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | Niri component stack and architecture |
| [02-CONFIGURATION](./02-CONFIGURATION.md) | Config file structure (legacy Hyprland) |
| [03-KEYBINDINGS](./03-KEYBINDINGS.md) | Keyboard shortcuts (legacy Hyprland) |
| [04-MONITORS](./04-MONITORS.md) | Display configuration (legacy Hyprland) |
| [05-WAYBAR](./05-WAYBAR.md) | Status bar |
| [06-LAUNCHERS](./06-LAUNCHERS.md) | Launchers (legacy Hyprland — now uses Fuzzel) |
| [07-NOTIFICATIONS](./07-NOTIFICATIONS.md) | Notifications (legacy Hyprland — now uses Dunst) |
| [08-LOCKSCREEN](./08-LOCKSCREEN.md) | Lock screen (legacy Hyprland — now uses swaylock) |
| [09-THEMING](./09-THEMING.md) | Colors and wallpapers |
| [10-TERMINALS](./10-TERMINALS.md) | Terminal emulators |
| [11-CUSTOMIZATION](./11-CUSTOMIZATION.md) | Custom configs (legacy Hyprland) |
| [12-KEYRING](./12-KEYRING.md) | GNOME Keyring credential storage |
| [13-REMOTE-ACCESS](./13-REMOTE-ACCESS.md) | VNC remote desktop via SSH tunnel |
| [14-NIRI](./14-NIRI.md) | Niri compositor (primary reference) |
| [15-SDDM](./15-SDDM.md) | SDDM display manager and Sequoia theme |

## Component Stack

| Component | Choice |
|-----------|--------|
| **Compositor** | Niri |
| **Config** | acaibowlz/niri-setup |
| **Bar** | Waybar |
| **Launcher** | Fuzzel |
| **Notifications** | Dunst |
| **Lock Screen** | swaylock-effects |
| **Idle Daemon** | swayidle |
| **Wallpaper** | swww + swaybg |
| **Terminal** | Alacritty |
| **File Manager** | Nautilus |
| **Keyring** | GNOME Keyring |
| **Display Manager** | SDDM (Sequoia theme) |

## Quick Reference

### Essential Keybindings

| Key | Action |
|-----|--------|
| `Mod+Return` | Terminal (Alacritty) |
| `Mod+Q` | Close window |
| `Mod+Space` | Application launcher (Fuzzel) |
| `Mod+B` | Browser |
| `Mod+E` | File manager |
| `Mod+F` | Fullscreen |
| `Mod+T` | Toggle floating |
| `Mod+C` | Clipboard history |
| `Mod+Backspace` | Logout menu (wlogout) |
| `Print` | Screenshot |

### Quick Commands

```bash
# Validate config
niri validate

# Reload config
niri msg action load-config-file

# List outputs
niri msg outputs

# Restart Waybar
pkill waybar; waybar &
```

## Configuration Location

```
~/.config/niri-setup/     # Main config repo (symlinked)
├── niri/                 # → ~/.config/niri
├── waybar/               # → ~/.config/waybar
├── dunst/                # → ~/.config/dunst
├── fuzzel/               # → ~/.config/fuzzel
├── wlogout/              # → ~/.config/wlogout
├── alacritty/            # → ~/.config/alacritty
├── scripts/              # → ~/.config/niri-scripts
└── niriswitcher/         # → ~/.config/niriswitcher
```

## Related

- [../hardware/03-INPUT-DEVICES.md](../hardware/03-INPUT-DEVICES.md) - Input configuration
- [../hardware/04-DISPLAY-GRAPHICS.md](../hardware/04-DISPLAY-GRAPHICS.md) - Display settings
- [../systemd/07-DESKTOP-SERVICES.md](../systemd/07-DESKTOP-SERVICES.md) - User services
