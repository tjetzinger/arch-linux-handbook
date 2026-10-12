# 04 - Power Management

Power management services for the ThinkPad X1 Carbon Gen 11.

## Service Summary

| Service | Purpose | Status |
|---------|---------|--------|
| tlp | Advanced power management | Running |
| intel_pstate | CPU frequency driver, governor set by TLP | Kernel built-in |
| upower | Power device monitoring | Running |

`cpupower` and `laptop-mode-tools` are not installed. TLP does both jobs.

## System Information

```
System: ThinkPad X1 Carbon Gen 11
CPU: Intel (13th Gen)
Kernel: linux-cachyos (fallbacks: linux-zen, linux-lts)
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

## CPU Frequency (intel_pstate)

The `intel_pstate` driver scales the CPU. TLP sets the governor and the energy policy (`CPU_SCALING_GOVERNOR_ON_BAT=powersave`, `CPU_ENERGY_PERF_POLICY_ON_BAT=power` in `/etc/tlp.d/10-thinkpad.conf`).

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver     # intel_pstate
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor   # powersave
sudo tlp-stat -p                                            # TLP view of the CPU
```

With intel_pstate, `powersave` still boosts under load. The energy policy decides how eagerly.

## laptop-mode-tools (removed)

Not installed, and `/etc/laptop-mode/` is gone. `systemctl list-timers --all` still shows `laptop-mode.timer` as a leftover entry without a unit file. TLP covers its job.

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
# In /etc/tlp.d/10-thinkpad.conf (drop-in overrides /etc/tlp.conf)
START_CHARGE_THRESH_BAT0=85
STOP_CHARGE_THRESH_BAT0=90
```

```bash
# Check thresholds
sudo tlp-stat -b | grep -i threshold

# Set manually
echo 90 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
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

**Kernel parameters** (in every boot entry, for example `/boot/loader/entries/linux-cachyos.conf`):
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

Controlled by systemd-logind, independent of the idle daemon (swayidle).

**Current settings** (query via D-Bus):

```bash
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitchDocked
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitchExternalPower
```

| Setting | Default | Current | When |
|---------|---------|---------|------|
| `HandleLidSwitch` | suspend | suspend | On battery, no external monitor |
| `HandleLidSwitchDocked` | ignore | ignore | External monitor connected |
| `HandleLidSwitchExternalPower` | (inherit) | ignore | On AC power (set by `10-lid-switch.conf`) |

**To disable lid suspend on AC power** (already done on this system):

```bash
sudo mkdir -p /etc/systemd/logind.conf.d
cat << 'EOF' | sudo tee /etc/systemd/logind.conf.d/10-lid-switch.conf
[Login]
HandleLidSwitchExternalPower=ignore
EOF
sudo systemctl reload systemd-logind   # not restart: that ends the session
```

The live drop-in is `10-lid-switch.conf`, see [hardware/02-POWER-BATTERY - Lid Switch Behavior](../hardware/02-POWER-BATTERY.md#lid-switch-behavior).

**All available actions:** `ignore`, `poweroff`, `reboot`, `halt`, `suspend`, `hibernate`, `lock`

### Idle Suspend (swayidle)

Under Niri, idle handling is `swayidle`, started by `~/.config/niri-setup/scripts/swayidle.sh` from `spawn-at-startup.kdl`. The idle time comes from `~/.local/state/idle-time` and is changed with Mod+I. It is separate from lid behaviour.

| Trigger | Source | Current |
|---------|--------|---------|
| Lid close | logind | suspend on battery, ignore on AC or docked |
| Idle | swayidle | `infinity`, so no idle actions |

With a finite idle time (for example `10 minutes`), the script locks the screen, powers off the monitors and suspends after 30 minutes. See [desktop/14-NIRI](../desktop/14-NIRI.md).

## Service Interaction

```
Boot
  │
  ├── tlp.service (applies power settings)
  │
  └── intel_pstate (TLP sets governor and energy policy)

Power Event (AC/Battery)
  │
  └── TLP adjusts settings automatically
```

## Quick Reference

```bash
# TLP
sudo tlp-stat
sudo tlp-stat -b          # Battery
sudo tlp-stat -p          # Processor
sudo tlp ac/bat           # Force mode

# CPU frequency
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# upower
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Suspend
systemctl suspend
```

## Related

- [08-HARDWARE](./08-HARDWARE.md) - Hardware services
- [02-CORE-SERVICES](./02-CORE-SERVICES.md) - logind configuration
