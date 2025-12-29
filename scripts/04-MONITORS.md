# 04 - Monitor Management Scripts

Scripts for multi-monitor setups and dock/undock workflows.

## Toggle Monitors (toggle-monitors.sh)

**Location:** `~/.config/hypr/scripts/toggle-monitors.sh`

Manual control for switching between laptop and external monitor modes.

### Usage

```bash
# Auto-detect and configure
~/.config/hypr/scripts/toggle-monitors.sh auto

# Force dock mode (external monitors only)
~/.config/hypr/scripts/toggle-monitors.sh dock

# Force undock mode (laptop screen only)
~/.config/hypr/scripts/toggle-monitors.sh undock
```

### Modes

| Mode | Description | Monitors Enabled |
|------|-------------|------------------|
| `auto` | Detect externals, configure automatically | Based on detection |
| `dock` | External monitors only | DP-6, DP-7 |
| `undock` | Laptop display only | eDP-1 |

### Monitor Configuration

Default positions configured in script:

```bash
# Dock mode
hyprctl keyword monitor "eDP-1,disable"
hyprctl keyword monitor "DP-6,preferred,0x0,1"
hyprctl keyword monitor "DP-7,preferred,1920x0,1"

# Undock mode
hyprctl keyword monitor "eDP-1,preferred,960x1200,1"
```

### Customizing for Your Setup

Edit monitor names and positions to match your hardware:

```bash
# Find your monitor names
hyprctl monitors -j | jq -r '.[].name'
```

### Example Keybindings

```ini
# Toggle monitor setup
bind = $mainMod CTRL, M, exec, ~/.config/hypr/scripts/toggle-monitors.sh auto

# Quick dock/undock
bind = $mainMod CTRL SHIFT, M, exec, ~/.config/hypr/scripts/toggle-monitors.sh dock
bind = $mainMod CTRL ALT, M, exec, ~/.config/hypr/scripts/toggle-monitors.sh undock
```

## Monitor Switch (monitor-switch.sh) - ARCHIVED

**Location:** `~/.config/hypr/scripts/monitor-switch.sh`

Auto-detection daemon that monitors for display changes.

### Status

This script is currently **disabled** - uses hardcoded DP-6/DP-7 names which
change on each dock reconnection. Use `hyprdynamicmonitors` or description-based
monitor config instead.

### How It Works (When Enabled)

1. Runs initial monitor configuration on startup
2. Connects to Hyprland socket for events
3. Listens for `monitoradded` and `monitorremoved` events
4. Auto-reconfigures when monitors change

### Running as Service

If enabled, can be launched at startup:

```ini
# In autostart.conf
exec-once = ~/.config/hypr/scripts/monitor-switch.sh
```

### Event Handling

Uses socat to listen to Hyprland socket:

```bash
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
```

## Lid Switch Monitor (lid-switch-monitor.sh)

**Location:** `~/.config/hypr/scripts/lid-switch-monitor.sh`

Handle laptop lid open/close events.

### Integration

This script works with:
- systemd logind lid switch events
- Hyprland monitor configuration
- External monitor detection

### Typical Logic

```bash
# When lid closes with external monitor
# - Disable laptop display
# - Keep external monitors active

# When lid opens
# - Re-enable laptop display if needed
```

### Configuration

Lid behavior also configured in:
- `/etc/systemd/logind.conf` - System level
- Hyprland `misc` section - Desktop level

See [../hardware/03-POWER-BATTERY](../hardware/03-POWER-BATTERY.md) for details.

## Move Windows (moveTo.sh)

**Location:** `~/.config/hypr/scripts/moveTo.sh`

Move all windows from current workspace to another.

### Usage

```bash
~/.config/hypr/scripts/moveTo.sh [target_workspace]
```

### Example

```bash
# Move all windows from current workspace to workspace 5
~/.config/hypr/scripts/moveTo.sh 5
```

### How It Works

1. Gets current active workspace
2. Finds all window addresses in that workspace
3. Moves each window to target workspace (silently)
4. Switches to target workspace

### Example Keybindings

```ini
# Move all windows to workspaces 1-10
bind = $mainMod CTRL, 1, exec, ~/.config/hypr/scripts/moveTo.sh 1
bind = $mainMod CTRL, 2, exec, ~/.config/hypr/scripts/moveTo.sh 2
# ... etc
```

## Monitor Configuration Reference

### Finding Monitor Names

```bash
# List all monitors
hyprctl monitors

# JSON format for scripting
hyprctl monitors -j | jq -r '.[].name'
```

### Common Monitor Names

| Type | Common Names |
|------|--------------|
| Laptop | eDP-1, eDP-2 |
| DisplayPort | DP-1, DP-2, DP-6, DP-7 |
| HDMI | HDMI-A-1, HDMI-A-2 |
| USB-C | DP-3, DP-4 |

### Monitor Configuration Syntax

```bash
# Format: name,resolution,position,scale
hyprctl keyword monitor "DP-6,preferred,0x0,1"
hyprctl keyword monitor "DP-7,1920x1080@60,1920x0,1"
hyprctl keyword monitor "eDP-1,disable"
```

### Persistent Configuration

For permanent setup, use `~/.config/hypr/conf/monitor.conf`:

```ini
# Dual external monitors
monitor = DP-6, preferred, 0x0, 1
monitor = DP-7, preferred, 1920x0, 1
monitor = eDP-1, disable

# Or laptop only
# monitor = eDP-1, preferred, 0x0, 1
```

## Troubleshooting

### Monitor Not Detected

```bash
# Check connected monitors
hyprctl monitors -j

# Check available outputs
wlr-randr
```

### Wrong Monitor Names

Monitor names can change with:
- Different ports used
- Dock connection order
- USB-C alt mode

Use `hyprctl monitors` to find current names.

### Display Manager Issues

If SDDM shows on wrong monitor, configure in:
- `/etc/sddm.conf.d/` - SDDM configuration
- Or use `disabledm.sh` for TTY login

## Related

- [02-DESKTOP-CONTROL](./02-DESKTOP-CONTROL.md) - Power and system control
- [../hardware/01-OVERVIEW](../hardware/01-OVERVIEW.md) - Hardware configuration
- [../desktop/02-HYPRLAND-CONFIG](../desktop/02-HYPRLAND-CONFIG.md) - Hyprland settings
