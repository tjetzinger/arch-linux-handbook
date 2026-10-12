# 03 - Input Devices

TrackPoint, touchpad, and keyboard configuration.

> Desktop: **Niri** (since 2026-02-20). Input settings live in `~/.config/niri/input.kdl`, included from `config.kdl`. Niri reloads the config automatically when the file is saved. The earlier Hyprland setup is archived, see [desktop/11-CUSTOMIZATION](../desktop/11-CUSTOMIZATION.md).

## Device Overview

```bash
sudo libinput list-devices | grep -E '^Device:'
```

| Device | Type | Driver |
|--------|------|--------|
| ELAN TrackPoint (`TPPS/2 Elan TrackPoint`) | Pointing stick | libinput |
| ELAN Touchpad (`ELAN067C:00 04F3:31F9 Touchpad`) | Multi-touch | libinput |
| ThinkPad Keyboard (`AT Translated Set 2 keyboard`) | Internal keyboard | libinput |

## Current Niri Configuration

**File:** `~/.config/niri/input.kdl`

```kdl
input {
    keyboard {
        xkb {
            layout "de"
            variant "nodeadkeys"
            options "caps:escape"
        }
    }
    touchpad {
        tap
        natural-scroll
    }
    mouse {
        natural-scroll
    }
    focus-follows-mouse
}
```

Everything not set here (TrackPoint, acceleration, disable-while-typing) uses the libinput defaults.

Check the config and the active layout:

```bash
niri validate                 # syntax check of the config
niri msg keyboard-layouts     # * 0 German (no dead keys)
```

Full option list: https://github.com/YaLTeR/niri/wiki/Configuration:-Input

## TrackPoint

The red pointing stick between G, H, and B. Not configured in Niri, so it runs with libinput defaults. Scrolling works by holding the middle button and moving the TrackPoint.

Example to remove acceleration and raise the speed (not live):

```kdl
input {
    trackpoint {
        accel-profile "flat"
        accel-speed 0.5
    }
}
```

## Touchpad

Live: tap-to-click and natural scrolling. Other options go in the same `touchpad` block, for example (not live):

```kdl
touchpad {
    tap
    natural-scroll
    dwt                          // disable while typing
    accel-speed 0.2
    disabled-on-external-mouse
}
```

### Acceleration

| `accel-profile` | Behaviour | Use case |
|-----------------|-----------|----------|
| `"adaptive"` | Acceleration (libinput default) | Touchpad, mice |
| `"flat"` | No acceleration (1:1) | TrackPoint, precise control |

`accel-speed` ranges from `-1.0` (slowest) to `1.0` (fastest), `0.0` is the default.

## Physical Buttons

The TrackPoint buttons (above touchpad):

| Button | Function |
|--------|----------|
| Left | Primary click |
| Middle | Scroll (with TrackPoint) |
| Right | Context menu |

## Keyboard

### Layout

- Layout: `de` (German), variant `nodeadkeys`
- Caps Lock acts as Escape (`caps:escape`)
- The same `keyboard` block applies to every keyboard, including Bluetooth ones like the Logitech MX Keys Mini. No per-device config is needed.

### Console Keymap

```bash
localectl status   # VC Keymap: de-latin1-nodeadkeys
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

Gets the German layout from the global `keyboard` block in `input.kdl`. Check after connecting:

```bash
niri msg keyboard-layouts
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

```kdl
input {
    touchpad {
        off
    }
}
```

Or only while an external mouse is connected: `disabled-on-external-mouse` in the `touchpad` block.

## Troubleshooting

### Device Not Working

```bash
# Check if device is detected
sudo libinput list-devices

# Watch raw input events
sudo libinput debug-events

# Check kernel messages
dmesg | grep -i -E 'input|elan'
journalctl -b | grep -i touchpad
```

### Config Change Has No Effect

```bash
niri validate                 # a syntax error stops the reload
journalctl --user -u niri -b | tail -20
```

## Quick Reference

```bash
# Input devices
sudo libinput list-devices

# Active keyboard layout
niri msg keyboard-layouts

# Validate config after editing ~/.config/niri/input.kdl
niri validate

# Keyboard backlight
echo 2 | sudo tee /sys/class/leds/tpacpi::kbd_backlight/brightness
```

## Related

- [08-PERIPHERALS](./08-PERIPHERALS.md) - External mice
- [../systemd/08-HARDWARE.md](../systemd/08-HARDWARE.md) - logid for Logitech
- [../desktop/14-NIRI.md](../desktop/14-NIRI.md) - Niri setup
