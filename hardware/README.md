# Hardware Documentation

Hardware-specific configuration for the ThinkPad X1 Carbon Gen 11.

## Contents

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | System specifications |
| [02-POWER-BATTERY](./02-POWER-BATTERY.md) | Power management and battery |
| [03-INPUT-DEVICES](./03-INPUT-DEVICES.md) | TrackPoint, touchpad, keyboard |
| [04-DISPLAY-GRAPHICS](./04-DISPLAY-GRAPHICS.md) | Intel Iris Xe graphics |
| [05-AUDIO](./05-AUDIO.md) | Audio configuration |
| [06-NETWORKING-HW](./06-NETWORKING-HW.md) | WiFi 6E and Bluetooth |
| [07-BIOMETRICS](./07-BIOMETRICS.md) | Fingerprint reader |
| [08-PERIPHERALS](./08-PERIPHERALS.md) | External devices |
| [09-FIRMWARE](./09-FIRMWARE.md) | BIOS and firmware updates |
| [10-EGPU](./10-EGPU.md) | External GPU (Razer Core X + RTX 3060) |
| [11-CUSTOM-KERNEL](./11-CUSTOM-KERNEL.md) | Custom optimized kernel (linux-zen-x1c) |
| [12-CACHYOS](./12-CACHYOS.md) | CachyOS repository and kernel with sched-ext |

## System Summary

| Component | Specification |
|-----------|---------------|
| **Model** | ThinkPad X1 Carbon Gen 11 (21HM) |
| **CPU** | Intel Core i7-1370P (6P+8E, 20 threads) |
| **RAM** | 64 GB |
| **Storage** | 2 TB KIOXIA NVMe (XG8) |
| **Display** | 14" 1920x1200 (16:10) |
| **GPU** | Intel Iris Xe Graphics |
| **WiFi** | Intel AX211 (WiFi 6E) |
| **Battery** | 57 Wh (design capacity) |

## Key Features

- **Thunderbolt 4** - Two USB-C/TB4 ports
- **Fingerprint Reader** - Synaptics Prometheus
- **TrackPoint** - ELAN with physical buttons
- **Webcam** - Chicony 1080p with IR

## Quick Reference

```bash
# System info
sudo dmidecode -t system | head -15

# Hardware sensors
sensors

# Battery status
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Firmware updates
fwupdmgr get-updates

# Input devices
hyprctl devices
```

## Linux Compatibility

This system has excellent Linux support:

| Component | Status | Notes |
|-----------|--------|-------|
| CPU | Working | Full P/E core support |
| GPU | Working | i915/xe driver |
| WiFi | Working | iwlwifi driver |
| Bluetooth | Working | Intel AX211 |
| Fingerprint | Working | fprintd |
| Webcam | Working | uvcvideo |
| Thunderbolt | Working | Native support |
| Audio | Working | sof-hda driver |
| Suspend | Working | s2idle mode |

## Related

- [../systemd/04-POWER-MANAGEMENT.md](../systemd/04-POWER-MANAGEMENT.md) - TLP service
- [../systemd/08-HARDWARE.md](../systemd/08-HARDWARE.md) - Hardware services
