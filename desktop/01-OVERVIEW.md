# 01 - Overview

Hyprland compositor with ML4W dotfiles configuration.

## Hyprland

Dynamic tiling Wayland compositor.

### Version

```bash
hyprctl version
```

```
Hyprland 0.52.2
Tag: v0.52.2
```

### Features

- Dynamic tiling and floating windows
- Smooth animations and effects
- Multi-monitor support
- Plugin system
- IPC for scripting

## ML4W Dotfiles

**My Linux 4 Work** - A comprehensive Hyprland configuration.

### Source

- GitHub: [mylinuxforwork/dotfiles](https://github.com/mylinuxforwork/dotfiles)
- Wiki: [ML4W Wiki](https://github.com/mylinuxforwork/dotfiles/wiki)

### Components Included

| Component | Description |
|-----------|-------------|
| Hyprland config | Organized, modular configuration |
| Waybar | Themed status bar |
| Rofi | Application launcher |
| SwayNC | Notification center |
| hyprlock | Lock screen |
| hypridle | Idle management |
| waypaper | Wallpaper manager |
| ML4W apps | Settings, Welcome, Sidebar |

### ML4W Applications

```bash
# Welcome app
ml4w-welcome

# Hyprland settings
ml4w-hyprland-settings

# Sidebar
ml4w-sidebar
```

## Installed Plugin

### split-monitor-workspaces

Provides per-monitor workspaces (like i3/bspwm behavior).

```bash
hyprpm list
```

```
Repository split-monitor-workspaces:
  Plugin split-monitor-workspaces - enabled: true
```

### Configuration

In `~/.config/hypr/conf/custom.conf`:

```bash
plugin {
    split-monitor-workspaces {
        count = 3
        keep_focused = 0
        enable_notifications = 0
    }
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Hyprland                             │
│  ┌─────────────────────────────────────────────────────┐│
│  │                    Waybar                           ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │   Window    │  │   Window    │  │     Window      │ │
│  │   (Warp)    │  │  (Firefox)  │  │    (Nautilus)   │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │              nwg-dock-hyprland                      ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘

Supporting Services:
├── hypridle (idle management)
├── hyprpaper (wallpaper)
├── swaync (notifications)
├── polkit-gnome (authentication)
└── wl-paste + cliphist (clipboard)
```

## Session Startup

On login, Hyprland sources autostart configuration:

1. XDG portal setup
2. Polkit agent
3. Wallpaper restore
4. SwayNC notifications
5. GTK settings
6. hypridle
7. cliphist clipboard
8. ML4W autostart
9. nwg-dock
10. hyprdynamicmonitors
11. hyprpm plugins

## Default Applications

| Type | Application |
|------|-------------|
| Terminal | Warp |
| Browser | Firefox |
| File Manager | Nautilus |
| Editor | Code/VSCode |
| Screenshot | grim + slurp |

### Check/Change Defaults

```bash
# View current settings
cat ~/.config/ml4w/settings/terminal.sh
cat ~/.config/ml4w/settings/browser.sh
cat ~/.config/ml4w/settings/filemanager.sh

# Or use ML4W Settings app
ml4w-hyprland-settings
```

## Key Directories

```
~/.config/hypr/
├── hyprland.conf       # Main config (sources others)
├── hypridle.conf       # Idle/lock timeouts
├── hyprlock.conf       # Lock screen appearance
├── hyprpaper.conf      # Wallpaper config
├── colors.conf         # Pywal colors
├── monitors.conf       # Monitor config (symlink)
├── conf/               # Modular configs
│   ├── autostart.conf
│   ├── keybinding.conf
│   ├── custom.conf     # Your customizations
│   └── ...
├── scripts/            # Helper scripts
└── shaders/            # Visual effects
```

## Quick Reference

```bash
# Hyprland version
hyprctl version

# Reload config
hyprctl reload

# List plugins
hyprpm list

# ML4W apps
ml4w-welcome
ml4w-hyprland-settings

# Check monitors
hyprctl monitors

# List keybindings
~/.config/hypr/scripts/keybindings.sh
```

## Related

- [02-CONFIGURATION](./02-CONFIGURATION.md) - Config structure
- [03-KEYBINDINGS](./03-KEYBINDINGS.md) - Keyboard shortcuts
- [11-CUSTOMIZATION](./11-CUSTOMIZATION.md) - Custom configs
