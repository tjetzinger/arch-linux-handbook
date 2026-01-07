# 01 - Overview

ThinkPad X1 Carbon Gen 11 system specifications and hardware details.

## System Information

```bash
sudo dmidecode -t system
```

| Field | Value |
|-------|-------|
| Manufacturer | LENOVO |
| Product | 21HMCTO1WW |
| Version | ThinkPad X1 Carbon Gen 11 |
| Family | ThinkPad X1 Carbon Gen 11 |

## CPU

**Intel Core i7-1370P (Raptor Lake-P)**

```bash
lscpu
```

| Specification | Value |
|---------------|-------|
| Architecture | x86_64 |
| Cores | 14 (6 P-cores + 8 E-cores) |
| Threads | 20 |
| Base Frequency | 1.9 GHz (P-cores) |
| Max Turbo | 5.2 GHz |
| Cache | L3: 24 MB |
| TDP | 28W (configurable 20-64W) |

### Core Types

- **P-cores (Performance)**: 6 cores with Hyper-Threading (12 threads)
- **E-cores (Efficiency)**: 8 cores without HT (8 threads)

### CPU Features

```bash
# View features
lscpu | grep Flags

# Key features
- VT-x (virtualization)
- AES-NI (encryption)
- AVX2/AVX-VNNI
- Intel Thread Director
```

## Memory

```bash
free -h
sudo dmidecode -t memory
```

| Specification | Value |
|---------------|-------|
| Total | 64 GB |
| Type | LPDDR5 |
| Speed | 6400 MT/s |
| Form Factor | Soldered (not upgradeable) |

## Storage

**KIOXIA XG8 NVMe SSD**

```bash
lsblk
nvme list
```

| Specification | Value |
|---------------|-------|
| Capacity | 2 TB |
| Interface | PCIe 4.0 x4 |
| Form Factor | M.2 2280 |
| Controller | KIOXIA NVMe |

### Partitions

```
nvme0n1         2TB
├─nvme0n1p1     32G   /boot (EFI, VFAT)
└─nvme0n1p2     1.8T  LUKS encrypted
  └─cryptroot   1.8T  Btrfs
```

## Display

**AU Optronics 0xD291**

```bash
hyprctl monitors
```

| Specification | Value |
|---------------|-------|
| Size | 14 inches |
| Resolution | 1920x1200 |
| Aspect Ratio | 16:10 |
| Refresh Rate | 60 Hz |
| Panel Type | IPS |
| Physical Size | 300x190 mm |

## Graphics

**Intel Iris Xe Graphics (integrated)**

```bash
lspci | grep VGA
vainfo
```

| Specification | Value |
|---------------|-------|
| Driver | i915 / xe |
| Video Decode | VA-API (H.264, HEVC, VP9, AV1) |
| Video Encode | H.264, HEVC |

## Ports and Connectivity

### USB/Thunderbolt

| Port | Type | Features |
|------|------|----------|
| 2x USB-C | Thunderbolt 4 | 40 Gbps, DP Alt Mode, charging |
| 2x USB-A | USB 3.2 Gen 1 | 5 Gbps |

### Other Ports

- HDMI 2.0b
- 3.5mm headphone/mic combo
- SIM card slot (WWAN models)

## Wireless

### WiFi

**Intel AX211 (WiFi 6E)**

```bash
lspci | grep Network
iwctl device list
```

| Specification | Value |
|---------------|-------|
| Standard | WiFi 6E (802.11ax) |
| Bands | 2.4/5/6 GHz |
| Max Speed | 2.4 Gbps |
| Driver | iwlwifi |

### Bluetooth

```bash
bluetoothctl show
```

| Specification | Value |
|---------------|-------|
| Version | Bluetooth 5.3 |
| Driver | btusb (Intel) |

## Input Devices

```bash
hyprctl devices
```

| Device | Type |
|--------|------|
| ELAN TrackPoint | Pointing stick |
| ELAN Touchpad | Multi-touch touchpad |
| ThinkPad Keyboard | German layout |

## Biometrics

**Synaptics Prometheus Fingerprint Reader**

```bash
lsusb | grep Synaptics
fprintd-list $USER
```

| Specification | Value |
|---------------|-------|
| Vendor | Synaptics (06cb:00fc) |
| Type | Touch sensor |
| Driver | fprintd |

## Camera

**Chicony Integrated Camera**

```bash
lsusb | grep Chicony
v4l2-ctl --list-devices
```

| Specification | Value |
|---------------|-------|
| Resolution | 1080p |
| Features | IR camera for Windows Hello |
| Privacy | Physical shutter |

## Battery

```bash
upower -i /org/freedesktop/UPower/devices/battery_BAT0
```

| Specification | Value |
|---------------|-------|
| Model | 5B10W13973 |
| Design Capacity | 57 Wh |
| Current Capacity | ~49 Wh (86% health) |
| Cycle Count | 110 |
| Cells | 4-cell Li-poly |

**Health Status**: Battery at 86% health with 110 cycles shows higher degradation than typical. Monitor monthly and consider replacement when health drops below 80%.

**See**: [02-POWER-BATTERY.md](./02-POWER-BATTERY.md) for battery health monitoring, replacement procedure, and vendor recommendations.

## Thermal

```bash
sensors
```

| Sensor | Location |
|--------|----------|
| coretemp | CPU package and cores |
| thinkpad | Fan speed, chassis |
| nvme | SSD temperature |
| iwlwifi | WiFi module |
| acpitz | ACPI thermal zone |

## Kernel Modules

ThinkPad-specific modules:

```bash
lsmod | grep thinkpad
```

| Module | Purpose |
|--------|---------|
| thinkpad_acpi | Fan control, LEDs, hotkeys |
| platform_profile | Performance profiles |

## Quick Reference

```bash
# Full hardware info
sudo dmidecode

# CPU info
lscpu

# Memory
free -h

# Storage
lsblk
nvme list

# PCI devices
lspci

# USB devices
lsusb

# Sensors
sensors
```

## Related

- [02-POWER-BATTERY](./02-POWER-BATTERY.md) - Power management
- [04-DISPLAY-GRAPHICS](./04-DISPLAY-GRAPHICS.md) - Graphics details
- [09-FIRMWARE](./09-FIRMWARE.md) - BIOS updates
