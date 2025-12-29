# 11 - Customization

Adding custom configurations to Hyprland/ML4W.

## Golden Rule

**Never edit ML4W default files directly.** Use the designated custom files instead.

## custom.conf

The main file for your customizations.

**File:** `~/.config/hypr/conf/custom.conf`

### What Goes Here

- Environment variables
- Device-specific settings
- Plugin configuration
- Additional keybindings
- Custom window rules
- Sourcing additional configs

### Example Content

```bash
# Environment variables
env = SDL_VIDEODRIVER,wayland
env = QT_QPA_PLATFORMTHEME,qt5ct

# Device-specific: Mouse scroll inversion
device {
    name = m585/m590-mouse
    natural_scroll = true
}

# Plugin configuration
plugin {
    split-monitor-workspaces {
        count = 3
        keep_focused = 0
        enable_notifications = 0
    }
}

# Additional keybindings
bind = $mainMod, H, exec, warp-terminal -e htop

# Custom window rules
windowrule = float,class:(calculator)
windowrule = size 400 600,class:(calculator)

# Source additional custom files
source = ~/.config/hypr/conf/ttkeyboard.conf
```

## Adding Keybindings

### In custom.conf

```bash
# Variables (already defined in keybindings)
$mainMod = SUPER
$HYPRSCRIPTS = ~/.config/hypr/scripts
$SCRIPTS = ~/.config/ml4w/scripts

# New keybinding
bind = $mainMod, H, exec, warp-terminal -e htop
bind = $mainMod ALT, F, exec, firefox --private-window
bind = $mainMod, N, exec, nautilus
```

### Keybinding Syntax

```bash
bind = MODIFIERS, key, dispatcher, params

# Examples
bind = $mainMod, Q, killactive
bind = $mainMod, F, fullscreen, 0
bind = $mainMod, T, exec, warp-terminal
bind = $mainMod SHIFT, S, exec, ~/.config/hypr/scripts/screenshot.sh
```

### Modifiers

| Modifier | Key |
|----------|-----|
| SUPER | Super/Windows key |
| SHIFT | Shift |
| CTRL | Control |
| ALT | Alt |

### Bind Types

| Type | Description |
|------|-------------|
| bind | Standard binding |
| binde | Repeats while held |
| bindm | Mouse binding |
| bindl | Works when locked |
| bindr | On key release |

## Window Rules

### Syntax

```bash
windowrule = RULE, MATCH
windowrulev2 = RULE, MATCH1, MATCH2, ...
```

### Common Rules

```bash
# Float a window
windowrule = float,class:(pavucontrol)

# Set size
windowrule = size 800 600,class:(pavucontrol)

# Set position
windowrule = move 100 100,class:(myapp)

# Center window
windowrule = center,class:(myapp)

# Pin (always on top)
windowrule = pin,class:(myapp)

# Opacity
windowrule = opacity 0.9,class:(myapp)

# Workspace assignment
windowrule = workspace 2,class:(firefox)
```

### Match Criteria

```bash
class:(regex)      # Window class
title:(regex)      # Window title
initialClass:(regex)
initialTitle:(regex)
```

### Find Window Class

```bash
# List all windows with class
hyprctl clients | grep class

# Or use hyprprop (click on window)
# Might need to install hyprland-contrib
```

## Environment Variables

### In custom.conf

```bash
env = VARIABLE,value
```

### Common Variables

```bash
# Wayland
env = SDL_VIDEODRIVER,wayland
env = GDK_BACKEND,wayland
env = QT_QPA_PLATFORM,wayland

# Qt theming
env = QT_QPA_PLATFORMTHEME,qt5ct

# Cursor
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Bibata-Modern-Classic

# XDG
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
```

## Autostart

### Adding Autostart Apps

Edit `~/.config/hypr/conf/autostart.conf` or add to custom.conf:

```bash
# Run once at startup
exec-once = /path/to/app

# Run every config reload
exec = /path/to/script
```

### Examples

```bash
exec-once = nm-applet
exec-once = blueman-applet
exec-once = /usr/lib/kdeconnectd
```

## Custom Scripts

### Location

```bash
~/.config/hypr/scripts/
~/.config/ml4w/scripts/
```

### Create Script

```bash
#!/bin/bash
# ~/.config/hypr/scripts/my-script.sh

# Your commands here
notify-send "Hello" "Script executed"
```

```bash
chmod +x ~/.config/hypr/scripts/my-script.sh
```

### Use in Keybinding

```bash
bind = $mainMod, X, exec, ~/.config/hypr/scripts/my-script.sh
```

## Plugins

### Installing Plugins

```bash
# Add plugin repository
hyprpm add https://github.com/username/plugin

# Enable plugin
hyprpm enable plugin-name

# Update plugins
hyprpm update
```

### Plugin Config

In custom.conf:

```bash
plugin {
    plugin-name {
        setting1 = value
        setting2 = value
    }
}
```

### Current Plugin

**split-monitor-workspaces** - Per-monitor workspaces

```bash
plugin {
    split-monitor-workspaces {
        count = 3
        keep_focused = 0
        enable_notifications = 0
    }
}
```

## ML4W Settings App

GUI for many settings:

```bash
ml4w-hyprland-settings
```

Generates config at:
```
~/.config/com.ml4w.hyprlandsettings/
```

## Testing Changes

### Reload Config

```bash
hyprctl reload

# Or keybinding
# Super + Ctrl + R
```

### Check for Errors

```bash
# Watch logs while reloading
journalctl --user -f | grep -i hypr
```

### Validate Window Rules

```bash
# List active rules
hyprctl getoption windowrule
```

## Backup Custom Config

```bash
# Before major changes
cp ~/.config/hypr/conf/custom.conf ~/.config/hypr/conf/custom.conf.bak
```

## Quick Reference

```bash
# Edit custom config
$EDITOR ~/.config/hypr/conf/custom.conf

# Reload config
hyprctl reload

# List windows (for rules)
hyprctl clients

# List monitors
hyprctl monitors

# Check devices (for device config)
hyprctl devices

# Plugin management
hyprpm list
hyprpm add <repo>
hyprpm enable <plugin>
```

## Related

- [02-CONFIGURATION](./02-CONFIGURATION.md) - Config structure
- [03-KEYBINDINGS](./03-KEYBINDINGS.md) - Keybinding reference
- [01-OVERVIEW](./01-OVERVIEW.md) - Plugin information
