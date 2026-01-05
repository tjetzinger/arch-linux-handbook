# 05 - Audio

Audio configuration with PipeWire and Intel HDA.

## Hardware

### Sound Card

```bash
lspci | grep Audio
```

```
Intel Corporation Raptor Lake-P/U/H cAVS (rev 01)
```

### Audio Devices

```bash
wpctl status
```

Devices:
- **Speakers**: Built-in stereo speakers
- **Headphone**: 3.5mm combo jack
- **HDMI**: Audio output via HDMI/DisplayPort

## PipeWire

Modern audio server replacing PulseAudio.

### Services

```bash
systemctl --user status pipewire
systemctl --user status pipewire-pulse
systemctl --user status wireplumber
```

| Service | Purpose |
|---------|---------|
| pipewire | Core audio server |
| pipewire-pulse | PulseAudio compatibility |
| wireplumber | Session manager |

### Check Status

```bash
# PipeWire info
pw-cli info all | head -20

# Audio devices
wpctl status
```

## Volume Control

### Command Line

```bash
# Get volume
wpctl get-volume @DEFAULT_AUDIO_SINK@

# Set volume (0.0 to 1.0)
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5

# Set volume percentage
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%

# Increase/decrease
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

# Mute toggle
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Mute on/off
wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
```

### Hyprland Keybinds

```bash
# In hyprland.conf
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
```

## Output Selection

### List Sinks

```bash
wpctl status
# Or
pactl list sinks short
```

### Switch Output

```bash
# Get sink IDs
wpctl status | grep -A 10 "Sinks:"

# Set default sink
wpctl set-default <sink-id>
```

### Common Sinks

| Device | Description |
|--------|-------------|
| Built-in speakers | Laptop speakers |
| Headphones | 3.5mm jack (when connected) |
| HDMI | External display audio |
| Bluetooth | Bluetooth headphones/speakers |

## Input (Microphone)

### List Sources

```bash
wpctl status | grep -A 10 "Sources:"
```

### Microphone Control

```bash
# Get mic volume
wpctl get-volume @DEFAULT_AUDIO_SOURCE@

# Set mic volume
wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 80%

# Mute mic
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
```

### Set Default Microphone

```bash
wpctl set-default <source-id>
```

## Bluetooth Audio

### Connect Bluetooth Device

```bash
bluetoothctl
> connect <MAC>
```

### Switch to Bluetooth

```bash
# Device should appear automatically in wpctl status
wpctl set-default <bluetooth-sink-id>
```

### Bluetooth Audio Codecs

PipeWire supports:
- SBC (standard)
- AAC
- aptX / aptX HD
- LDAC

### Bluetooth Hardware Volume Issue

Some Bluetooth devices (like eMeet Luna) have hardware volume sync issues where volume keys don't change the audio level, or changes happen on the wrong device.

**Symptoms:**
- Volume keys don't affect Bluetooth audio
- Volume slider moves but audio level doesn't change
- Keyboard/mouse volume controls affect wrong device

**Solution: Disable Bluetooth Hardware Volume**

Create WirePlumber config to use software volume only:

**File:** `/etc/wireplumber/wireplumber.conf.d/99-disable-bt-hw-volume.conf`

```
monitor.bluez.properties = {
  bluez5.enable-hw-volume = false
}
```

**Apply:**
```bash
systemctl --user restart wireplumber
# Reconnect Bluetooth device
bluetoothctl disconnect <MAC>
bluetoothctl connect <MAC>
```

This forces all Bluetooth volume control through PipeWire's software mixer, ensuring volume keys work correctly.

## Configuration

### PipeWire Config

**Locations:**
- System: `/usr/share/pipewire/`
- User: `~/.config/pipewire/`

### WirePlumber Config

**Location:** `~/.config/wireplumber/`

Example device profile:
```lua
-- ~/.config/wireplumber/main.lua.d/51-alsa-config.lua
rule = {
  matches = {
    {
      { "node.name", "matches", "alsa_output.*" },
    },
  },
  apply_properties = {
    ["audio.format"] = "S32LE",
    ["audio.rate"] = 48000,
  },
}
```

## USB Audio Devices

USB audio devices (like eMeet Luna, USB docks) often have limited hardware volume range, causing no sound below ~25% volume.

### Symptom

Volume slider works from 25-100%, but 0-25% produces no sound.

### Fix: Software Volume

Create WirePlumber config to use software volume control:

**File:** `~/.config/wireplumber/wireplumber.conf.d/51-usb-audio-soft-volume.conf`

```
monitor.alsa.rules = [
  {
    matches = [
      {
        device.name = "alsa_card.usb-eMeet_eMeet_Luna_20080411-00"
      }
    ]
    actions = {
      update-props = {
        api.alsa.soft-mixer = true
        api.alsa.ignore-dB = true
      }
    }
  }
  {
    matches = [
      {
        device.name = "~alsa_card.usb-Lenovo_ThinkPad_USB-C_Dock_*"
      }
    ]
    actions = {
      update-props = {
        api.alsa.soft-mixer = true
        api.alsa.ignore-dB = true
      }
    }
  }
]
```

### Find Device Name

```bash
pw-dump | jq -r '.[] | select(.info.props."device.name" | test("usb")) | .info.props."device.name"'
```

### Apply

```bash
systemctl --user restart wireplumber
```

**Note:** With soft-mixer, ~20% is the practical minimum volume due to PipeWire's cubic volume curve.

## Troubleshooting

### No Sound

```bash
# Check services
systemctl --user status pipewire wireplumber

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check if muted
wpctl get-volume @DEFAULT_AUDIO_SINK@
```

### Check ALSA

```bash
# List cards
cat /proc/asound/cards

# Test output
speaker-test -c 2
```

### Logs

```bash
# PipeWire logs
journalctl --user -u pipewire

# WirePlumber logs
journalctl --user -u wireplumber

# Verbose logging
PIPEWIRE_DEBUG=3 pipewire
```

### Audio Crackling/Popping

```bash
# Increase buffer size
# In ~/.config/pipewire/pipewire.conf.d/99-custom.conf
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 512
}
```

### Wrong Default Device

```bash
# List devices with IDs
wpctl status

# Set default
wpctl set-default <id>
```

## HDMI Audio

### Check HDMI Output

```bash
wpctl status | grep -i hdmi
```

### Switch to HDMI

```bash
wpctl set-default <hdmi-sink-id>
```

### Troubleshoot HDMI

```bash
# Check if HDMI audio is detected
aplay -l | grep HDMI

# Force HDMI output
pactl set-card-profile alsa_card.pci-0000_00_1f.3 output:hdmi-stereo
```

## Per-Application Volume

PipeWire stores volume levels per-application. This can cause volume inconsistencies between apps.

### Check Application Volumes

```bash
pactl list sink-inputs | grep -E "(Sink Input|application.name|Volume:)"
```

### Set Application Volume

```bash
# List sink inputs to find the ID
pactl list sink-inputs short

# Set specific app volume (ID from above)
pactl set-sink-input-volume <ID> 100%
```

### VLC Volume Boost

VLC may sound quieter than other apps (like Chrome/YouTube). Fix with audio normalization and gain:

**Edit:** `~/.config/vlc/vlcrc`

```bash
# Enable volume normalizer and gain filter
audio-filter=normvol:gain

# Normalization max level (2.5 = 250% boost ceiling)
norm-max-level=2.500000

# Gain multiplier (4.0 = 400% boost)
gain-value=4.000000
```

**Or via CLI:**

```bash
sed -i 's/^#audio-filter=$/audio-filter=normvol:gain/' ~/.config/vlc/vlcrc
sed -i 's/^#norm-max-level=.*$/norm-max-level=2.500000/' ~/.config/vlc/vlcrc
sed -i 's/^#gain-value=.*$/gain-value=4.000000/' ~/.config/vlc/vlcrc
```

Restart VLC after changes.

## GUI Tools

### pavucontrol

```bash
pavucontrol
```

Features:
- Per-application volume
- Output/input device selection
- Device configuration

### Helvum

```bash
helvum
```

PipeWire graph viewer and patchbay.

## Quick Reference

```bash
# Volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Status
wpctl status

# Default device
wpctl set-default <id>

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber

# Test speakers
speaker-test -c 2

# Logs
journalctl --user -u pipewire
```

## Related

- [../systemd/07-DESKTOP-SERVICES.md](../systemd/07-DESKTOP-SERVICES.md) - PipeWire services
- [06-NETWORKING-HW](./06-NETWORKING-HW.md) - Bluetooth audio
