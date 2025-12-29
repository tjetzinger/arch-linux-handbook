# 04 - Display and Graphics

Intel Iris Xe graphics and display configuration.

## Display

### Panel Information

```bash
hyprctl monitors
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
hyprctl monitors
```

```
Monitor eDP-1 (ID 0):
    1920x1200@60.02600 at 0x0
    scale: 1.00
    transform: 0
    dpmsStatus: 1
```

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

### Hyprland Keybinds

```bash
# In hyprland.conf
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
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
hyprctl monitors
```

### Configure External Monitor

**File:** `~/.config/hypr/hyprland.conf`

```bash
# Mirror
monitor=HDMI-A-1,preferred,0x0,1,mirror,eDP-1

# Extend (to the right)
monitor=eDP-1,1920x1200@60,0x0,1
monitor=HDMI-A-1,2560x1440@60,1920x0,1

# Only external
monitor=eDP-1,disable
monitor=HDMI-A-1,2560x1440@60,0x0,1
```

### Runtime Monitor Configuration

```bash
# List monitors
hyprctl monitors

# Disable internal
hyprctl keyword monitor eDP-1,disable

# Enable with position
hyprctl keyword monitor HDMI-A-1,2560x1440@60,1920x0,1
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

Hyprland doesn't have built-in night light. Use:

```bash
# gammastep
gammastep -O 4500K

# Or in config for Wayland
gammastep -m wayland
```

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

### Hyprland Keybinds

```bash
# In hyprland.conf
bind = , Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bind = SHIFT, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
```

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
# Turn off display
hyprctl dispatch dpms off

# Turn on display
hyprctl dispatch dpms on

# Idle timeout in hyprland.conf
misc {
    dpms_timeout = 300  # 5 minutes
}
```

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
# Force detection
hyprctl monitors

# Check DRM
cat /sys/class/drm/card0-HDMI-A-1/status
```

## Quick Reference

```bash
# Monitor info
hyprctl monitors

# Brightness
brightnessctl set 50%

# VA-API
vainfo

# Screenshot
grim ~/screenshot.png

# DPMS
hyprctl dispatch dpms off/on

# External monitor
hyprctl keyword monitor HDMI-A-1,2560x1440@60,1920x0,1
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Hardware specs
- [02-POWER-BATTERY](./02-POWER-BATTERY.md) - Power management
