# 04 - Power Management

Power management services for the ThinkPad X1 Carbon Gen 11.

## Service Summary

| Service | Purpose | Status |
|---------|---------|--------|
| tlp | Advanced power management | Running |
| cpupower | CPU frequency/governor | Running |
| laptop-mode-tools | Additional power savings | Running (timer) |
| upower | Power device monitoring | Running |

## System Information

```
System: ThinkPad X1 Carbon Gen 11
CPU: Intel (13th Gen)
Kernel: linux-lts
Suspend: s2idle
```

## TLP

Advanced power management for Linux laptops.

### Status

```bash
systemctl status tlp
tlp-stat -s
```

### Service Type

TLP is a one-shot service that applies settings at boot:

```ini
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/tlp init start
```

### Configuration

**Main file:** `/etc/tlp.conf`
**Drop-in directory:** `/etc/tlp.d/` (overrides main file)

**ThinkPad-specific:** `/etc/tlp.d/10-thinkpad.conf`
```bash
PLATFORM_PROFILE_ON_BAT=low-power
PCIE_ASPM_ON_BAT=powersupersave
USB_AUTOSUSPEND=1
WIFI_PWR_ON_BAT=on
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_BAT=power
SATA_LINKPWR_ON_BAT=min_power
RESTORE_DEVICE_STATE_ON_STARTUP=0
```

Key settings in main config:
```bash
# CPU governor
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Disk
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

# WiFi power save
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# USB autosuspend
USB_AUTOSUSPEND=1
```

### TLP and systemd-rfkill

**Important:** `RESTORE_DEVICE_STATE_ON_STARTUP` controls whether TLP manages radio devices (WiFi, Bluetooth) at boot.

| Value | Behavior |
|-------|----------|
| `0` | Let systemd-rfkill handle radio state persistence |
| `1` | TLP manages radio state (requires masking systemd-rfkill) |

If using `RESTORE_DEVICE_STATE_ON_STARTUP=1`, you must mask systemd-rfkill:
```bash
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
```

**Recommended:** Use `RESTORE_DEVICE_STATE_ON_STARTUP=0` and let systemd-rfkill handle it (no masking required).

### Commands

```bash
# Full status
sudo tlp-stat

# Battery info
sudo tlp-stat -b

# Processor info
sudo tlp-stat -p

# Apply AC settings
sudo tlp ac

# Apply battery settings
sudo tlp bat

# Show config
tlp-stat -c
```

### Power Profiles

**Note:** `power-profiles-daemon` was removed as it conflicts with TLP. TLP handles all power profile switching automatically based on AC/battery state.

```bash
# Check current TLP mode
tlp-stat -s

# Force AC mode
sudo tlp ac

# Force battery mode
sudo tlp bat
```

## cpupower

CPU frequency scaling control.

### Status

```bash
systemctl status cpupower
cpupower frequency-info
```

### Configuration

**File:** `/etc/default/cpupower`

```bash
# CPU governor
governor='powersave'

# Optional frequency limits
#min_freq="2.25GHz"
#max_freq="3GHz"
```

### Commands

```bash
# Current frequency
cpupower frequency-info

# Set governor
sudo cpupower frequency-set -g powersave
sudo cpupower frequency-set -g performance

# Monitor frequency
watch -n1 cpupower frequency-info | grep "current CPU"
```

### Available Governors

| Governor | Description |
|----------|-------------|
| powersave | Lowest frequency |
| performance | Highest frequency |
| schedutil | Kernel scheduler controlled |

## laptop-mode-tools

Additional power management (works alongside TLP).

### Timer

```bash
systemctl status laptop-mode.timer
```

**File:** `/usr/lib/systemd/system/laptop-mode.timer`

```ini
[Timer]
OnUnitActiveSec=150s
OnActiveSec=150s
Unit=lmt-poll.service
```

Polls battery status every 150 seconds.

### Configuration

**Directory:** `/etc/laptop-mode/`

**Main config:** `/etc/laptop-mode/laptop-mode.conf`

Key settings:
```bash
ENABLE_LAPTOP_MODE_TOOLS=1
ENABLE_LAPTOP_MODE_ON_BATTERY=1
ENABLE_LAPTOP_MODE_ON_AC=0
MINIMUM_BATTERY_CHARGE_PERCENT=3
```

### Module Configs

```
/etc/laptop-mode/conf.d/
├── battery-level-polling.conf
├── cpufreq.conf
├── hdparm.conf
├── intel-sata-powermgmt.conf
├── lcd-brightness.conf
└── ...
```

### Commands

```bash
# Check status
sudo laptop_mode status

# Force enable
sudo laptop_mode force

# Manual start
sudo laptop_mode auto
```

## upower

Power device monitoring (battery, UPS).

### Status

```bash
systemctl status upower
upower -i /org/freedesktop/UPower/devices/battery_BAT0
```

### Commands

```bash
# List devices
upower -e

# Battery info
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Monitor events
upower -m
```

## Battery Health

### Check Status

```bash
# Via upower
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Via TLP
sudo tlp-stat -b

# Via sysfs
cat /sys/class/power_supply/BAT0/capacity
cat /sys/class/power_supply/BAT0/status
```

### Charge Thresholds (ThinkPad)

TLP can set charge thresholds to preserve battery longevity:

```bash
# In /etc/tlp.conf
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
```

```bash
# Check thresholds
sudo tlp-stat -b | grep -i threshold

# Set manually
echo 80 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
```

## Suspend/Hibernate

### Current Mode

```bash
cat /sys/power/mem_sleep
# [s2idle] deep
```

This system uses s2idle (modern standby) for suspend.

### Suspend

```bash
systemctl suspend
```

Works reliably with USB dock connected.

### Hibernate

Hibernate saves RAM to swap and powers off completely.

#### Configuration

| Component | Value |
|-----------|-------|
| Swap location | `/swap/swapfile` (72GB) |
| Swap subvolume | `@swap` (excluded from snapshots) |
| Resume device | `/dev/mapper/cryptroot` |
| Resume offset | `126887168` |

**Kernel parameters** (in `/boot/loader/entries/arch-lts.conf`):
```
resume=/dev/mapper/cryptroot resume_offset=126887168
```

**fstab entries**:
```bash
# @swap subvolume
UUID=7baf5627-b3c5-4add-8b0e-fdd3488f00e0  /swap  btrfs  rw,relatime,ssd,discard,space_cache=v2,subvol=/@swap  0 0
/swap/swapfile none swap defaults 0 0
```

#### Usage

```bash
# Standard hibernate
systemctl hibernate

# Safe hibernate (warns about USB dock)
safe-hibernate
```

#### Known Limitation: USB-C Dock

**Issue**: Hibernate resume fails with USB-C dock connected.

```
xhci_hcd 0000:00:14.0: PM: pci_pm_freeze(): hcd_pci_suspend returns -16
PM: hibernation: Failed to load image, recovering.
```

The xhci_hcd driver cannot freeze when USB devices have pending async operations. This is a kernel-level limitation.

**Workaround**: Disconnect USB-C dock before hibernating.

The `safe-hibernate` script (`/usr/local/bin/safe-hibernate`) warns if dock is connected:
```bash
#!/bin/bash
if lsusb | grep -q "ThinkPad USB-C Dock"; then
    echo "⚠️  USB dock detected! Disconnect before hibernating."
    read -t 10 || exit 1
fi
systemctl hibernate
```

#### Verify Swap

```bash
swapon --show
# NAME           TYPE SIZE USED PRIO
# /swap/swapfile file  72G   0B   -2
```

#### Get Resume Offset (if swap file recreated)

```bash
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

### Lid Switch Behavior

**File:** `/etc/systemd/logind.conf`

```ini
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
```

## Service Interaction

```
Boot
  │
  ├── tlp.service (applies power settings)
  │
  ├── cpupower.service (sets CPU governor)
  │
  └── laptop-mode.timer (starts polling)
        │
        └── lmt-poll.service (every 150s)

Power Event (AC/Battery)
  │
  ├── TLP adjusts settings automatically
  │
  └── laptop-mode reacts to battery level
```

## Quick Reference

```bash
# TLP
sudo tlp-stat
sudo tlp-stat -b          # Battery
sudo tlp-stat -p          # Processor
sudo tlp ac/bat           # Force mode

# cpupower
cpupower frequency-info
sudo cpupower frequency-set -g <governor>

# laptop-mode
sudo laptop_mode status

# upower
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Suspend
systemctl suspend
```

## Related

- [08-HARDWARE](./08-HARDWARE.md) - Hardware services
- [02-CORE-SERVICES](./02-CORE-SERVICES.md) - logind configuration
