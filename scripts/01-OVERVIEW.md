# 01 - Scripts Overview

Complete inventory of custom scripts.

## Script Locations

| Directory | Count | Purpose |
|-----------|-------|---------|
| `~/.config/hypr/scripts/` | 26 | Hyprland desktop scripts |
| `~/.config/ml4w/scripts/` | 11 | ML4W utility scripts |
| `~/.config/ml4w/scripts/arch/` | 7 | Arch-specific scripts |

**Total: 44 scripts**

## Hyprland Scripts

### System/Desktop Control

| Script | Purpose | Keybinding |
|--------|---------|------------|
| power.sh | Lock, suspend, shutdown, hibernate | Super+Ctrl+L (lock) |
| screenshot.sh | Interactive screenshot capture | Super+P |
| systeminfo.sh | Display Hyprland system info | - |
| cleanup.sh | Startup cleanup (auto) | - |

### Theming/Visual

| Script | Purpose | Keybinding |
|--------|---------|------------|
| wallpaper.sh | Complete wallpaper management | - |
| wallpaper-restore.sh | Restore wallpaper on startup | Auto |
| wallpaper-effects.sh | Apply effects to wallpaper | - |
| wallpaper-automation.sh | Random wallpaper rotation | Super+Alt+W |
| wallpaper-cache.sh | Clear wallpaper cache | - |
| init-wallpaper-engine.sh | Initialize wallpaper engine | Auto |
| hyprshade.sh | Color/shader filters | Super+Shift+H |
| gamemode.sh | Toggle performance mode | Super+Alt+G |
| toggle-animations.sh | Toggle animations | Super+Shift+A |
| toggleallfloat.sh | Toggle all windows floating | - |

### Utility/Configuration

| Script | Purpose | Keybinding |
|--------|---------|------------|
| keybindings.sh | Display keybindings | Super+Ctrl+K |
| loadconfig.sh | Reload Hyprland config | Super+Shift+R |
| gtk.sh | Sync GTK settings | Auto |
| xdg.sh | Setup XDG portal | Auto |
| disabledm.sh | Disable display manager | - |
| restart-hypridle.sh | Restart idle daemon | - |

### Hardware/Monitor

| Script | Purpose | Keybinding |
|--------|---------|------------|
| toggle-monitors.sh | Dock/undock switching | - |
| lid-switch-monitor.sh | Laptop lid handling | - |
| moveTo.sh | Move windows to workspace | Super+Ctrl+1-0 |

Note: `monitor-added.sh` and `monitor-switch.sh` archived - replaced by `hyprdynamicmonitors.service`.

### Daemon/Service

| Script | Purpose | Keybinding |
|--------|---------|------------|
| hypridle.sh | Toggle hypridle daemon | - |

## ML4W Scripts

### Main Scripts

| Script | Purpose |
|--------|---------|
| ags.sh | AGS service launcher |
| cliphist.sh | Clipboard history manager |
| figlet.sh | ASCII art text generator |
| installupdates.sh | System update manager |
| ml4w-autostart.sh | ML4W startup initialization |
| nm-applet.sh | Network Manager applet |
| sddm-wallpaper.sh | Set SDDM login wallpaper |
| shell.sh | Switch bash/zsh shells |
| thunarterminal.sh | Configure Thunar terminal |
| updates.sh | Update status checker |
| wlogout.sh | Logout menu configuration |

### Arch-Specific Scripts

| Script | Purpose |
|--------|---------|
| cleanup.sh | Package cache cleanup |
| installprinters.sh | Printer system setup |
| installtimeshift.sh | Timeshift backup setup |
| lid-improvements.sh | Laptop lid behavior config |
| pacman.sh | Pacman configuration manager |
| snapshot.sh | System snapshot creator |
| unlock-pacman.sh | Remove pacman database lock |

## Auto-Launch Scripts

These run automatically on Hyprland startup (via autostart.conf):

| Script | Purpose |
|--------|---------|
| xdg.sh | XDG portal and waybar setup |
| wallpaper-restore.sh | Restore last wallpaper |
| gtk.sh | GTK theme synchronization |
| cleanup.sh | Startup cleanup |
| init-wallpaper-engine.sh | Wallpaper engine init |

## Dependencies

Scripts require these tools:

| Tool | Used By |
|------|---------|
| hyprctl | Most scripts (Hyprland IPC) |
| rofi | Menu scripts (screenshot, wallpaper-effects, keybindings) |
| matugen | wallpaper.sh (color generation) |
| grimblast | screenshot.sh |
| magick | wallpaper.sh (ImageMagick) |
| jq | JSON processing scripts |
| wl-copy | Clipboard scripts |
| hyprlock | power.sh |
| hypridle | Idle management |
| swaync | Notifications |
| waypaper | Wallpaper selection |

## Settings Files

Scripts use configuration from `~/.config/ml4w/settings/`:

```
~/.config/ml4w/settings/
├── wallpaper-folder.sh      # Wallpaper directory
├── wallpaper-engine.sh      # swww/hyprpaper/disabled
├── wallpaper-effect.sh      # Current effect
├── screenshot-*.sh          # Screenshot settings
├── gamemode-enabled         # Game mode flag
└── ...
```

## Quick Reference

```bash
# List Hyprland scripts
ls ~/.config/hypr/scripts/

# List ML4W scripts
ls ~/.config/ml4w/scripts/

# Run a script
~/.config/hypr/scripts/screenshot.sh

# View script contents
cat ~/.config/hypr/scripts/gamemode.sh

# Make script executable
chmod +x ~/.config/hypr/scripts/myscript.sh
```

## Related

- [02-DESKTOP-CONTROL](./02-DESKTOP-CONTROL.md) - Power and screenshot scripts
- [03-WALLPAPER-THEMING](./03-WALLPAPER-THEMING.md) - Wallpaper scripts
- [08-CUSTOMIZATION](./08-CUSTOMIZATION.md) - Creating new scripts
