# 06 - Script Customization Guide

How to create, modify, and integrate custom scripts.

## Creating a New Script

### Basic Template

```bash
#!/bin/bash
# Script Name: myscript.sh
# Purpose: Description of what this does
# Usage: myscript.sh [options]

# Exit on error
set -e

# Your script logic here
echo "Script running..."
```

### Save Location

| Type | Location |
|------|----------|
| Hyprland desktop | `~/.config/hypr/scripts/` |
| Personal utilities | `~/.local/bin/` |
| ML4W specific | `~/.config/ml4w/scripts/` |

### Make Executable

```bash
chmod +x ~/.config/hypr/scripts/myscript.sh
```

## Adding Keybindings

Edit `~/.config/hypr/conf/keybinding.conf`:

```ini
# Run script with key combo
bind = $mainMod SHIFT, X, exec, ~/.config/hypr/scripts/myscript.sh

# With arguments
bind = $mainMod SHIFT, Y, exec, ~/.config/hypr/scripts/myscript.sh arg1 arg2
```

Reload config:
```bash
hyprctl reload
```

## Rofi Integration

### Basic Rofi Menu

```bash
#!/bin/bash

# Define options
options="Option 1\nOption 2\nOption 3"

# Show rofi and get selection
choice=$(echo -e "$options" | rofi -dmenu -p "Select" -config ~/.config/rofi/config-compact.rasi)

# Handle selection
case "$choice" in
    "Option 1")
        echo "Selected option 1"
        ;;
    "Option 2")
        echo "Selected option 2"
        ;;
    "Option 3")
        echo "Selected option 3"
        ;;
esac
```

### Rofi Config Options

Available configs in `~/.config/rofi/`:
- `config-compact.rasi` - Compact menu
- `config-screenshot.rasi` - Screenshot style
- `config-themes.rasi` - Theme selector style
- `config-hyprshade.rasi` - Shader selector

## Notifications

### Basic Notification

```bash
notify-send "Title" "Message body"
```

### With Options

```bash
# Timeout in milliseconds
notify-send -t 3000 "Quick" "This disappears in 3 seconds"

# Replace existing notification
notify-send --replace-id=1 "Progress" "Step 1 of 3" -h int:value:33
notify-send --replace-id=1 "Progress" "Step 2 of 3" -h int:value:66
notify-send --replace-id=1 "Progress" "Complete" -h int:value:100

# Urgency levels
notify-send -u low "Info" "FYI"
notify-send -u normal "Notice" "Something happened"
notify-send -u critical "Warning" "Important!"
```

## Waybar Integration

### JSON Output Script

```bash
#!/bin/bash
# Script outputs JSON for waybar custom module

if [ condition ]; then
    echo '{"text": "Active", "class": "active", "tooltip": "Feature is active"}'
else
    echo '{"text": "Inactive", "class": "inactive", "tooltip": "Feature is inactive"}'
fi
```

### Waybar Module Config

In `~/.config/waybar/config.jsonc`:

```json
"custom/mymodule": {
    "exec": "~/.config/hypr/scripts/myscript.sh status",
    "on-click": "~/.config/hypr/scripts/myscript.sh toggle",
    "return-type": "json",
    "interval": 5,
    "format": "{}"
}
```

## Hyprland IPC

### Common hyprctl Commands

```bash
# Get active window info
hyprctl activewindow -j | jq '.class'

# List all windows
hyprctl clients -j | jq '.[].title'

# Get monitor info
hyprctl monitors -j | jq '.[].name'

# Execute dispatcher
hyprctl dispatch workspace 3
hyprctl dispatch togglefloating
hyprctl dispatch killactive

# Set keyword temporarily
hyprctl keyword animations:enabled false

# Reload config
hyprctl reload
```

### Batch Commands

```bash
hyprctl --batch "\
    keyword animations:enabled 0;\
    keyword decoration:blur:enabled 0;\
    keyword general:gaps_in 0"
```

## Settings Files

### Reading Settings

```bash
# Source a settings file
source ~/.config/ml4w/settings/somesetting.sh

# Read a value
value=$(cat ~/.config/ml4w/settings/somesetting.sh)
```

### Writing Settings

```bash
# Save a setting
echo "myvalue" > ~/.config/ml4w/settings/mysetting.sh
```

### Toggle Files

Common pattern for toggle states:

```bash
toggle_file="$HOME/.config/ml4w/cache/feature-enabled"

if [ -f "$toggle_file" ]; then
    # Feature is on, turn it off
    rm "$toggle_file"
    # Disable feature...
else
    # Feature is off, turn it on
    touch "$toggle_file"
    # Enable feature...
fi
```

## Startup Scripts

### Add to Autostart

Edit `~/.config/hypr/conf/autostart.conf`:

```ini
# Run once at startup
exec-once = ~/.config/hypr/scripts/myscript.sh

# Run in background
exec-once = ~/.config/hypr/scripts/mydaemon.sh &
```

### Startup Order

Scripts run in order listed. Consider dependencies:
1. XDG portals (xdg.sh)
2. Theme sync (gtk.sh)
3. Wallpaper (wallpaper-restore.sh)
4. Waybar (via xdg.sh)
5. Your scripts

## Example: System Monitor Script

```bash
#!/bin/bash
# ~/.config/hypr/scripts/sysmon.sh
# Show system stats in notification

cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
mem=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
disk=$(df -h / | awk 'NR==2 {print $3 "/" $2}')

notify-send "System Monitor" "CPU: ${cpu}%\nMemory: ${mem}\nDisk: ${disk}"
```

## Example: Quick Toggle Script

```bash
#!/bin/bash
# ~/.config/hypr/scripts/toggle-blur.sh
# Toggle blur effect

if hyprctl getoption decoration:blur:enabled -j | jq -e '.int == 1' > /dev/null; then
    hyprctl keyword decoration:blur:enabled 0
    notify-send "Blur" "Disabled"
else
    hyprctl keyword decoration:blur:enabled 1
    notify-send "Blur" "Enabled"
fi
```

## Debugging Scripts

### Run with Debug Output

```bash
bash -x ~/.config/hypr/scripts/myscript.sh
```

### Log Output

```bash
# In your script
exec &>> /tmp/myscript.log
echo "$(date): Script started"
```

### Check Exit Codes

```bash
~/.config/hypr/scripts/myscript.sh
echo "Exit code: $?"
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - All available scripts
- [../desktop/03-KEYBINDINGS](../desktop/03-KEYBINDINGS.md) - Keybinding reference
- [../desktop/02-HYPRLAND-CONFIG](../desktop/02-HYPRLAND-CONFIG.md) - Hyprland configuration
