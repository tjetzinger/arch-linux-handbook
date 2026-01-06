# 03 - Input Devices

TrackPoint, touchpad, and keyboard configuration.

## Device Overview

```bash
hyprctl devices
```

| Device | Type | Driver |
|--------|------|--------|
| ELAN TrackPoint | Pointing stick | libinput |
| ELAN Touchpad | Multi-touch | libinput |
| ThinkPad Keyboard | Internal keyboard | evdev |

## TrackPoint

The iconic red pointing stick between G, H, and B keys.

### Device Info

```bash
hyprctl devices | grep -A 5 trackpoint
```

```
tpps/2-elan-trackpoint
    default speed: 0.00000
    scroll factor: -1.00
```

### Hyprland Configuration

**File:** `~/.config/hypr/hyprland.conf`

```bash
input {
    # TrackPoint sensitivity
    sensitivity = 0

    # TrackPoint section
    touchdevice {
        enabled = true
    }
}
```

### Adjust Sensitivity

```bash
# List input devices
hyprctl devices

# Set sensitivity (Hyprland)
# In hyprland.conf under device section
device {
    name = tpps/2-elan-trackpoint
    sensitivity = 0.5
}
```

### Middle Button Scrolling

TrackPoint scrolling uses the middle button + TrackPoint movement.

```bash
# Enable in Hyprland
input {
    scroll_method = on_button_down
    scroll_button = 274  # Middle button
}
```

## Touchpad

Multi-touch touchpad below the keyboard.

### Device Info

```bash
hyprctl devices | grep -A 5 touchpad
```

```
elan067c:00-04f3:31f9-touchpad
    default speed: 0.00000
    scroll factor: -1.00
```

### Hyprland Configuration

**File:** `~/.config/hypr/hyprland.conf`

```bash
input {
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
        drag_lock = false
        middle_button_emulation = true
    }
}
```

### Touchpad Settings

| Setting | Description |
|---------|-------------|
| natural_scroll | Scroll direction follows fingers |
| disable_while_typing | Disable touchpad while typing |
| tap-to-click | Tap to click enabled |
| drag_lock | Hold drag after lift |
| middle_button_emulation | Two-finger tap for middle click |

### Gestures

```bash
# In hyprland.conf
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
}
```

## Per-Device Acceleration & Speed

Configure acceleration and speed independently for each input device.

**File:** `~/.config/hypr/conf/custom.conf`

```bash
# Touchpad - enable acceleration, increase speed
device {
    name = elan067c:00-04f3:31f9-touchpad
    accel_profile = adaptive
    sensitivity = 0.4
}

# TrackPoint - disable acceleration, increase speed
device {
    name = tpps/2-elan-trackpoint
    natural_scroll = true
    accel_profile = flat
    sensitivity = 0.5
}
```

### Acceleration Profiles

| Profile | Behavior | Use Case |
|---------|----------|----------|
| `adaptive` | Acceleration enabled (default) | Touchpad, mice - fast movements go further |
| `flat` | No acceleration (1:1) | TrackPoint, gaming - precise control |
| `custom` | Custom curve with points | Advanced users |

### Sensitivity Range

| Value | Effect |
|-------|--------|
| `-1.0` | Slowest |
| `0.0` | Default (no modification) |
| `0.4` | Moderate speed increase |
| `0.5` | Noticeable speed increase |
| `1.0` | Fastest |

### Why Per-Device?

Different input devices need different settings:
- **Touchpad**: acceleration feels natural with finger gestures
- **TrackPoint**: no acceleration for precise control
- **Mice**: keep default adaptive acceleration

**Note:** `force_no_accel` is global-only in Hyprland. Use `accel_profile = flat` for per-device control.

## Physical Buttons

The TrackPoint buttons (above touchpad):

| Button | Function |
|--------|----------|
| Left | Primary click |
| Middle | Scroll (with TrackPoint) |
| Right | Context menu |

## Keyboard

### Layout

```bash
hyprctl devices | grep -A 5 "AT Translated"
```

Current configuration:
- Model: thinkpad
- Layout: de (German)
- Variant: nodeadkeys

### Hyprland Configuration

**File:** `~/.config/hypr/conf/keyboard.conf`

```bash
input {
    kb_layout = de
    kb_variant = nodeadkeys
    kb_model = thinkpad
    kb_options = caps:escape  # Caps Lock as Escape
}
```

### System-wide X11 Layout (SDDM Login Screen)

Set keyboard layout for SDDM and X11 sessions:

```bash
sudo localectl set-x11-keymap de "" nodeadkeys
```

This creates `/etc/X11/xorg.conf.d/00-keyboard.conf`:

```
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "de"
    Option "XkbVariant" "nodeadkeys"
EndSection
```

Verify:
```bash
localectl status
# X11 Layout: de
# X11 Variant: nodeadkeys
```

### Special Keys

ThinkPad function keys work via thinkpad_acpi:

| Key | Function |
|-----|----------|
| Fn+F1 | Mute |
| Fn+F2 | Volume down |
| Fn+F3 | Volume up |
| Fn+F4 | Mic mute |
| Fn+F5 | Brightness down |
| Fn+F6 | Brightness up |
| Fn+F7 | Display switch |
| Fn+F8 | Airplane mode |
| Fn+F9 | Settings |
| Fn+F10 | Bluetooth |
| Fn+F11 | Keyboard toggle |
| Fn+F12 | Star/Favorites |
| Fn+Space | Keyboard backlight |

### Keyboard Backlight

```bash
# Check backlight status
cat /sys/class/leds/tpacpi::kbd_backlight/brightness

# Set brightness (0, 1, 2)
echo 2 | sudo tee /sys/class/leds/tpacpi::kbd_backlight/brightness

# Or use Fn+Space to cycle
```

### Fn Lock

Toggle Fn lock with **Fn+Esc** to switch between:
- Function keys (F1-F12)
- Media/special keys (default)

## Bluetooth Keyboards

### Logitech MX Keys Mini

External Bluetooth keyboard requires device-specific configuration to maintain German layout.

**Device name:**
```bash
hyprctl devices | grep -i "mx-keys"
# mx-keys-mini-keyboard
```

**File:** `~/.config/hypr/conf/custom.conf`

```bash
# MX Keys Mini - force German layout
device {
    name = mx-keys-mini-keyboard
    kb_layout = de
    kb_variant = nodeadkeys
    kb_model =
}
```

**Note:** Remove `kb_model = thinkpad` for external keyboards to avoid layout conflicts.

### Why Device-Specific Config?

When a Bluetooth keyboard connects:
1. Hyprland assigns it default settings
2. Global `input {}` may not apply correctly to new devices
3. Device-specific `device {}` block ensures correct layout

### Apply Changes

```bash
hyprctl reload
```

Verify:
```bash
hyprctl devices | grep -A3 "mx-keys-mini-keyboard$"
# rules: r "", m "", l "de", v "nodeadkeys", o ""
# active keymap: German (no dead keys)
```

## libinput Configuration

For system-wide libinput settings:

**File:** `/etc/libinput/local-overrides.quirks`

Example quirks:
```ini
[Touchpad pressure]
MatchUdevType=touchpad
MatchName=*Touchpad*
AttrPressureRange=10:8
```

### List Capabilities

```bash
# Show device capabilities
sudo libinput list-devices
```

## Disable Devices

### Disable Touchpad

```bash
# Hyprland - per device
device {
    name = elan067c:00-04f3:31f9-touchpad
    enabled = false
}

# Or via hyprctl
hyprctl keyword device:elan067c:00-04f3:31f9-touchpad:enabled false
```

### Disable While External Mouse Connected

Can be scripted with udev rules.

## Troubleshooting

### Device Not Working

```bash
# Check if device is detected
hyprctl devices

# Check kernel messages
dmesg | grep -i input
dmesg | grep -i elan

# Check for driver issues
journalctl -b | grep -i touchpad
```

### Erratic Cursor Movement

```bash
# Adjust sensitivity
# In hyprland.conf
device {
    name = elan067c:00-04f3:31f9-touchpad
    sensitivity = -0.5  # Reduce sensitivity
}
```

### Scrolling Issues

```bash
# Check scroll settings
# Ensure natural_scroll matches your preference

input {
    touchpad {
        natural_scroll = true  # or false
        scroll_factor = 1.0    # Adjust if too fast/slow
    }
}
```

## Quick Reference

```bash
# List input devices
hyprctl devices

# Check libinput devices
sudo libinput list-devices

# Keyboard backlight
echo 2 | sudo tee /sys/class/leds/tpacpi::kbd_backlight/brightness

# Runtime config changes
hyprctl keyword input:touchpad:natural_scroll true
hyprctl keyword device:tpps/2-elan-trackpoint:sensitivity 0.5
```

## Related

- [08-PERIPHERALS](./08-PERIPHERALS.md) - External mice
- [../systemd/08-HARDWARE.md](../systemd/08-HARDWARE.md) - logid for Logitech
