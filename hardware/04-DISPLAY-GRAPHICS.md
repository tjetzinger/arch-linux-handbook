# 04 - Display and Graphics

Intel Iris Xe graphics and display configuration.

> Desktop: **Niri**. Output settings live in `~/.config/niri/outputs.kdl`; Niri reloads them when the file is saved. Hyprland-era commands (`hyprctl`) no longer apply.

## Display

### Panel Information

```bash
niri msg outputs
```

| Specification | Value |
|---------------|-------|
| Panel | AU Optronics 0xD291 |
| Resolution | 1920x1200 |
| Refresh Rate | 60 Hz |
| Physical Size | 300x190 mm (~14") |
| Aspect Ratio | 16:10 |
| Connection | eDP-1 (internal) |

### Current Configuration

```bash
niri msg outputs
```

```
Output "AU Optronics 0xD291 Unknown" (eDP-1)
  Current mode: 1920x1200 @ 60.026 Hz (preferred)
  Variable refresh rate: supported, disabled
  Scale: 1.25
  Logical size: 1536x960
```

The internal panel runs at scale 1.25.

## Intel Graphics

### GPU Information

```bash
lspci | grep VGA
```

```
Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
```

### Driver

```bash
lsmod | grep i915
# or for newer xe driver
lsmod | grep xe
```

| Driver | Status |
|--------|--------|
| i915 | Loaded (legacy) |
| xe | Available (newer) |

### GPU Status

```bash
# Intel GPU info
sudo intel_gpu_top

# DRM info
cat /sys/class/drm/card*/device/vendor
```

## Video Acceleration (VA-API)

Hardware video encoding/decoding.

### Check VA-API

```bash
vainfo
```

```
VA-API version: 1.22 (libva 2.22.0)
Driver version: Intel iHD driver for Intel(R) Gen Graphics - 25.3.4
```

### Supported Codecs

| Codec | Decode | Encode |
|-------|--------|--------|
| H.264 | Yes | Yes |
| HEVC (H.265) | Yes | Yes |
| VP9 | Yes | No |
| AV1 | Yes | No |
| MPEG-2 | Yes | Yes |
| VC-1 | Yes | No |

### Environment Variables

For Firefox/Chrome hardware acceleration:

```bash
# In ~/.config/environment.d/envvars.conf or shell profile
LIBVA_DRIVER_NAME=iHD
```

### Firefox Hardware Acceleration

In `about:config`:
```
media.ffmpeg.vaapi.enabled = true
gfx.webrender.all = true
```

### mpv Hardware Acceleration

```bash
# ~/.config/mpv/mpv.conf
hwdec=vaapi
vo=gpu
```

## Brightness Control

### Current Brightness

```bash
brightnessctl get
brightnessctl max
brightnessctl info
```

### Set Brightness

```bash
# Set percentage
brightnessctl set 50%

# Increase/decrease
brightnessctl set +10%
brightnessctl set 10%-
```

### Niri Keybinds

**File:** `~/.config/niri/binds.kdl`

```kdl
XF86MonBrightnessUp   allow-when-locked=true { spawn-sh "brightnessctl set +5%" ; }
XF86MonBrightnessDown allow-when-locked=true { spawn-sh "brightnessctl set 5%-" ; }
```

### Backlight Device

```bash
ls /sys/class/backlight/
# intel_backlight

cat /sys/class/backlight/intel_backlight/brightness
cat /sys/class/backlight/intel_backlight/max_brightness
```

## External Displays

### Ports

| Port | Maximum Resolution |
|------|-------------------|
| HDMI 2.0b | 4K@60Hz |
| USB-C/TB4 | 8K@60Hz / 4K@120Hz |

### Detect Displays

```bash
niri msg outputs
```

### Configure External Monitors

**File:** `~/.config/niri/outputs.kdl`

Docked layout in use: two BenQ BL2581T side by side, an HP 24m above the laptop, the laptop panel on the right. External monitors are matched by their EDID name (make, model, serial), so they keep their place even when the dock renumbers the ports.

```kdl
// Left external monitor
output "PNP(BNQ) BenQ BL2581T <serial>" {
    mode "1920x1200@59.950"
    scale 1.0
    position x=0 y=0
}

// Laptop panel
output "eDP-1" {
    mode "1920x1200@60.026"
    scale 1.25
    position x=3840 y=0
}
```

Turn an output off with `off` inside its block. Positions use logical pixels, so the laptop panel at scale 1.25 is 1536 px wide in the layout.

### Runtime Monitor Configuration

```bash
niri msg outputs             # list outputs with EDID names
niri msg output eDP-1 off    # temporary, not saved to the config
niri msg output eDP-1 on
```

## Color Management

### ICC Profiles

```bash
# Location
~/.local/share/icc/

# Apply with colormgr (if using colord)
colormgr device-get-default-profile
```

### Night Light

Niri has no built-in night light. `wlsunset` runs as a user service (`systemctl --user status wlsunset`), see [systemd/07-DESKTOP-SERVICES](../systemd/07-DESKTOP-SERVICES.md).

## Screen Recording

### wf-recorder

```bash
# Record screen
wf-recorder -f recording.mp4

# With audio
wf-recorder -a -f recording.mp4

# Specific output
wf-recorder -o eDP-1 -f recording.mp4
```

### OBS Studio

For OBS on Wayland, use the PipeWire screen capture.

## Screenshots

### grim

```bash
# Full screen
grim screenshot.png

# Region (with slurp)
grim -g "$(slurp)" screenshot.png

# Specific output
grim -o eDP-1 screenshot.png
```

### Niri Screenshots

Niri has built-in screenshots (`~/.config/niri/binds.kdl`):

| Key | Action |
|-----|--------|
| Print | Whole screen (`screenshot-screen`) |
| Ctrl+Print | Focused window (`screenshot-window`) |
| Shift+Print | Interactive selection (`screenshot`) |

Files go to `~/Pictures/Screenshots/` (`screenshot-path` in `misc.kdl`) and to the clipboard.

## Power Saving

### Intel GPU Power

```bash
# Check power state
cat /sys/class/drm/card0/device/power_state

# Panel Self Refresh (PSR) status
cat /sys/kernel/debug/dri/0/i915_edp_psr_status
```

### DPMS

```bash
# Turn off all displays (any input turns them back on)
niri msg action power-off-monitors
```

Idle handling is done by `swayidle`, started from `spawn-at-startup.kdl`, see [desktop/14-NIRI](../desktop/14-NIRI.md).

## Troubleshooting

### Screen Flickering

```bash
# Check for PSR issues
cat /sys/kernel/debug/dri/0/i915_edp_psr_status

# Disable PSR if problematic (kernel parameter)
i915.enable_psr=0
```

### No Hardware Acceleration

```bash
# Check VA-API
vainfo

# Ensure correct driver
export LIBVA_DRIVER_NAME=iHD
```

### External Monitor Not Detected

```bash
# List outputs Niri sees
niri msg outputs

# Check DRM
cat /sys/class/drm/card0-HDMI-A-1/status
```

## Quick Reference

```bash
# Monitor info
niri msg outputs

# Brightness
brightnessctl set 50%

# VA-API
vainfo

# Screenshot
grim ~/screenshot.png

# Displays off
niri msg action power-off-monitors

# Output on/off at runtime
niri msg output eDP-1 off
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Hardware specs
- [02-POWER-BATTERY](./02-POWER-BATTERY.md) - Power management
