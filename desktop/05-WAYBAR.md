# 05 - Waybar

Status bar configuration and customization.

## Overview

Waybar is a highly customizable status bar for Wayland.

### Location

```
~/.config/waybar/
├── launch.sh           # Launch script
├── toggle.sh           # Toggle visibility
├── themeswitcher.sh    # Theme switcher
├── colors.css          # Pywal colors
├── modules.json        # Module configuration
└── themes/             # Theme directories
```

## Launch/Control

### Start Waybar

```bash
~/.config/waybar/launch.sh
```

### Keybindings

| Key | Action |
|-----|--------|
| `Super + Shift + B` | Reload Waybar |
| `Super + Ctrl + B` | Toggle Waybar |
| `Super + Ctrl + T` | Theme switcher |

### Manual Control

```bash
# Restart
killall waybar && ~/.config/waybar/launch.sh

# Toggle visibility
~/.config/waybar/toggle.sh
```

## Configuration

### modules.json

**File:** `~/.config/waybar/modules.json`

This file defines all the bar modules and their settings.

### Module Types

| Type | Examples |
|------|----------|
| Built-in | clock, battery, network, pulseaudio |
| Custom | Scripts, commands |
| Hyprland | hyprland/workspaces, hyprland/window |

### Common Modules

```json
{
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}",
        "tooltip-format": "<tt>{calendar}</tt>"
    },
    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },
    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ipaddr}",
        "format-disconnected": "⚠ Disconnected"
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "",
        "on-click": "pavucontrol"
    }
}
```

## Themes

### Switch Theme

```bash
~/.config/waybar/themeswitcher.sh
# Or
# Super + Ctrl + T
```

### Theme Directory

```
~/.config/waybar/themes/
├── theme1/
│   ├── config
│   └── style.css
├── theme2/
│   └── ...
```

### Colors

**File:** `~/.config/waybar/colors.css`

Auto-generated from pywal:

```css
@define-color background #1a1b26;
@define-color foreground #c0caf5;
@define-color color0 #1a1b26;
@define-color color1 #f7768e;
/* ... */
```

## Styling

### CSS Structure

```css
/* Main bar */
#waybar {
    background: @background;
    color: @foreground;
}

/* Workspaces */
#workspaces button {
    padding: 0 5px;
}

#workspaces button.active {
    background: @color4;
}

/* Modules */
#clock {
    padding: 0 10px;
}

#battery.warning {
    color: @color3;
}

#battery.critical {
    color: @color1;
}
```

## Custom Modules

### Example: Script Module

```json
{
    "custom/weather": {
        "exec": "~/.config/waybar/scripts/weather.sh",
        "interval": 900,
        "return-type": "json",
        "format": "{} {icon}",
        "format-icons": ["", "", ""]
    }
}
```

### Example: On-Click Actions

```json
{
    "clock": {
        "on-click": "~/.config/ml4w/settings/calendar.sh",
        "on-click-right": "gnome-calendar"
    }
}
```

## ML4W Settings

The ML4W Hyprland Settings app can configure:

- Module visibility
- Position (top/bottom)
- Specific module settings

```bash
ml4w-hyprland-settings
```

### Setting Scripts

```
~/.config/ml4w/settings/
├── waybar_dateformat.sh
├── waybar_timeformat.sh
├── waybar_network.sh
├── waybar_systray.sh
├── waybar_taskbar.sh
└── ...
```

## Hyprland Integration

### Workspaces Module

```json
{
    "hyprland/workspaces": {
        "format": "{icon}",
        "on-click": "activate",
        "format-icons": {
            "1": "1",
            "2": "2",
            "3": "3",
            "urgent": "",
            "active": "",
            "default": ""
        }
    }
}
```

### Per-Monitor Workspaces (split-monitor-workspaces)

When using the **split-monitor-workspaces** Hyprland plugin, each monitor gets its own set of workspaces. By default, Waybar shows ALL workspaces on EACH monitor because of `all-outputs: true` in `modules.json`.

To show only each monitor's workspaces:

**Issue:** `~/.config/waybar/modules.json` has `"all-outputs": true` which shows all workspaces on every monitor.

**Solution:** Create a custom module override file and include it in the theme config.

1. Create `~/.config/waybar/modules-custom.json`:

```json
{
    "hyprland/workspaces": {
        "on-scroll-up": "hyprctl dispatch workspace r-1",
        "on-scroll-down": "hyprctl dispatch workspace r+1",
        "on-click": "activate",
        "active-only": false,
        "all-outputs": false,
        "format": "{}",
        "format-icons": {
            "urgent": "",
            "active": "",
            "default": ""
        },
        "persistent-workspaces": {
            "*": 3
        }
    }
}
```

2. Add to theme config includes (must be FIRST to override `modules.json`):

**File:** `~/.config/waybar/themes/<theme>/config`

```json
"include": [
    "~/.config/waybar/modules-custom.json",
    "~/.config/ml4w/settings/waybar-quicklinks.json",
    "~/.config/waybar/modules.json"
],
```

3. Restart waybar:
```bash
~/.config/waybar/launch.sh
```

**Result:** Each monitor shows only its assigned workspaces (e.g., DP-6: 4,5,6 / DP-7: 7,8,9).

**Migration Note:** The theme config file is hardlinked to ML4W and may be overwritten on updates. After ML4W updates, re-add `modules-custom.json` to the includes, or create a custom theme copy (see [11-CUSTOMIZATION](./11-CUSTOMIZATION.md)).

### Window Title

```json
{
    "hyprland/window": {
        "format": "{}",
        "max-length": 50,
        "separate-outputs": true
    }
}
```

## Troubleshooting

### Waybar Not Starting

```bash
# Check for errors
waybar -l debug

# Check logs
journalctl --user -u waybar
```

### Modules Not Showing

```bash
# Verify module is in bar config
cat ~/.config/waybar/modules.json | grep "module-name"

# Check module script (if custom)
~/.config/waybar/scripts/module.sh
```

### Styling Not Applied

```bash
# Check CSS syntax
# Reload waybar
~/.config/waybar/launch.sh
```

## Quick Reference

```bash
# Restart Waybar
~/.config/waybar/launch.sh

# Toggle visibility
~/.config/waybar/toggle.sh

# Theme switcher
~/.config/waybar/themeswitcher.sh

# Debug mode
waybar -l debug

# Edit modules
$EDITOR ~/.config/waybar/modules.json
```

## Related

- [09-THEMING](./09-THEMING.md) - Colors and themes
- [02-CONFIGURATION](./02-CONFIGURATION.md) - Config structure
