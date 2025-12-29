# 07 - Notifications

SwayNC notification center configuration.

## Overview

SwayNC (Sway Notification Center) is a notification daemon with a notification center panel.

## Configuration

**Directory:** `~/.config/swaync/`

```
~/.config/swaync/
├── config.json     # Main configuration
├── style.css       # Styling
└── colors.css      # Pywal colors
```

## Launch

Started automatically via autostart:

```bash
exec-once = swaync
```

## Usage

### Toggle Notification Center

```bash
swaync-client -t
```

Click the notification icon in Waybar or use the widget.

### Clear All Notifications

```bash
swaync-client -C
```

### Show/Hide Panel

```bash
swaync-client -t    # Toggle
swaync-client -op   # Open panel
swaync-client -cp   # Close panel
```

## Configuration

### config.json

**File:** `~/.config/swaync/config.json`

```json
{
    "positionX": "right",
    "positionY": "top",
    "layer": "overlay",
    "control-center-margin-top": 10,
    "control-center-margin-bottom": 10,
    "control-center-margin-right": 10,
    "control-center-margin-left": 10,
    "notification-icon-size": 64,
    "notification-body-image-height": 100,
    "notification-body-image-width": 200,
    "timeout": 10,
    "timeout-low": 5,
    "timeout-critical": 0,
    "fit-to-screen": true,
    "control-center-width": 400,
    "notification-window-width": 400,
    "keyboard-shortcuts": true,
    "image-visibility": "when-available",
    "transition-time": 200,
    "hide-on-clear": false,
    "hide-on-action": true,
    "script-fail-notify": true
}
```

### Key Settings

| Setting | Description |
|---------|-------------|
| positionX | Horizontal position (left/center/right) |
| positionY | Vertical position (top/bottom) |
| timeout | Default notification duration (seconds) |
| timeout-critical | Critical notification duration (0 = persistent) |
| control-center-width | Panel width in pixels |

## Styling

### style.css

**File:** `~/.config/swaync/style.css`

```css
/* Notification window */
.notification-row {
    outline: none;
}

.notification {
    border-radius: 12px;
    margin: 6px 12px;
    box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.3);
    padding: 0;
}

/* Control center */
.control-center {
    background: @background;
    border-radius: 12px;
    margin: 10px;
    padding: 10px;
}

/* Notification body */
.notification-content {
    padding: 10px;
}
```

### Pywal Integration

Colors are imported from `colors.css`:

```css
@import 'colors.css';
```

## Hyprland Integration

### Blur Effect

In ML4W config (`~/.config/hypr/conf/ml4w.conf`):

```bash
layerrule = blur, swaync-control-center
layerrule = blur, swaync-notification-window
layerrule = ignorezero, swaync-control-center
layerrule = ignorezero, swaync-notification-window
layerrule = ignorealpha 0.5, swaync-control-center
layerrule = ignorealpha 0.5, swaync-notification-window
```

## Widgets

SwayNC supports widgets in the control center:

```json
{
    "widgets": [
        "title",
        "dnd",
        "notifications",
        "mpris",
        "volume",
        "backlight"
    ]
}
```

### Available Widgets

| Widget | Description |
|--------|-------------|
| title | Header with clear button |
| dnd | Do Not Disturb toggle |
| notifications | Notification list |
| mpris | Media player controls |
| volume | Volume slider |
| backlight | Brightness slider |
| buttons-grid | Custom buttons |

## Do Not Disturb

### Toggle DND

```bash
swaync-client -d    # Toggle DND
swaync-client -D    # Get DND status
```

### In Control Center

Click the DND toggle in the notification panel.

## Testing

### Send Test Notification

```bash
notify-send "Title" "Body text"
notify-send -u critical "Critical" "This is urgent"
notify-send -i firefox "Firefox" "With icon"
```

### Urgency Levels

| Level | Behavior |
|-------|----------|
| low | Short timeout, subtle |
| normal | Default timeout |
| critical | No timeout, stays visible |

## Troubleshooting

### Notifications Not Showing

```bash
# Check if swaync is running
pgrep swaync

# Restart swaync
killall swaync && swaync &

# Test notification
notify-send "Test" "Hello"
```

### Wrong Styling

```bash
# Reload swaync
swaync-client -R

# Or restart
killall swaync && swaync &
```

### Check Logs

```bash
journalctl --user -u swaync
```

## Quick Reference

```bash
# Toggle notification center
swaync-client -t

# Clear all notifications
swaync-client -C

# Toggle DND
swaync-client -d

# Reload config
swaync-client -R

# Test notification
notify-send "Title" "Message"
```

## Related

- [05-WAYBAR](./05-WAYBAR.md) - Notification icon in Waybar
- [09-THEMING](./09-THEMING.md) - Color configuration
