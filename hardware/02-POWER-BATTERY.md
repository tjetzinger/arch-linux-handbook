# 02 - Power and Battery

Power management configuration for the ThinkPad X1 Carbon Gen 11.

## Battery Information

### Current Status

```bash
upower -i /org/freedesktop/UPower/devices/battery_BAT0
```

| Specification | Value |
|---------------|-------|
| Model | 5B10W13973 |
| Design Capacity | 57.05 Wh |
| Current Full Capacity | ~49 Wh |
| Technology | Li-ion |
| Voltage | ~16.35 V |

### Check Battery Health

```bash
# Via upower
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Via TLP
sudo tlp-stat -b

# Via sysfs
cat /sys/class/power_supply/BAT0/capacity
cat /sys/class/power_supply/BAT0/status
cat /sys/class/power_supply/BAT0/cycle_count
```

## Charge Thresholds

ThinkPads support charge thresholds to preserve battery longevity.

### Current Configuration

**File:** `/etc/tlp.d/10-thinkpad.conf`

```ini
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
```

This means:
- Charging starts when battery drops below 75%
- Charging stops when battery reaches 80%

### Why Use Thresholds?

- Li-ion batteries last longer when kept between 20-80%
- Prevents constant trickle charging when plugged in
- Recommended for laptops that are often docked

### Modify Thresholds

```bash
# Edit TLP custom config
sudo nano /etc/tlp.d/10-thinkpad.conf

# Modify threshold values
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80

# Apply changes
sudo tlp start
```

### Temporary Override

```bash
# Charge to full (for travel)
sudo tlp fullcharge BAT0

# Or set threshold temporarily
echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
```

## TLP Configuration

TLP provides automatic power management. Custom settings are in a drop-in file to survive package updates.

### Status

```bash
sudo tlp-stat -s
```

### Custom Configuration

**File:** `/etc/tlp.d/10-thinkpad.conf`

```ini
# Platform profile - balanced on AC for quieter fans
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power

# Aggressive power saving on battery
PCIE_ASPM_ON_BAT=powersupersave
WIFI_PWR_ON_BAT=on
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_BAT=power
SATA_LINKPWR_ON_BAT=min_power

# USB autosuspend (enabled)
USB_AUTOSUSPEND=1

# Battery charge thresholds (preserve longevity)
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80

# Don't restore radio device state
RESTORE_DEVICE_STATE_ON_STARTUP=0

# Disable CPU turbo boost on battery (saves 2-3W under load)
CPU_BOOST_ON_BAT=0

# Intel GPU frequency limits on battery (100-800 MHz)
# 100 MHz is hardware minimum (RPn), 800 MHz caps max for power savings
INTEL_GPU_MIN_FREQ_ON_BAT=100
INTEL_GPU_MAX_FREQ_ON_BAT=800
INTEL_GPU_BOOST_FREQ_ON_BAT=800
```

### Key Settings Explained

| Setting | Value | Effect |
|---------|-------|--------|
| PCIE_ASPM_ON_BAT | powersupersave | Enables L1.2 substates, critical for deep C-states (C8+) |
| CPU_BOOST_ON_BAT | 0 | Disables turbo boost, saves 2-3W under load |
| INTEL_GPU_MAX_FREQ_ON_BAT | 800 | Caps GPU at 800 MHz (vs 1500 MHz default) |
| CPU_ENERGY_PERF_POLICY_ON_BAT | power | Most aggressive CPU power saving |

**Note:** `PCIE_ASPM_ON_BAT=powersupersave` requires a **reboot** to take effect. Using `powersave` instead can prevent reaching deep package C-states.

### Platform Profile Explanation

| Profile | On AC | On Battery | Fan Behavior |
|---------|-------|------------|--------------|
| performance | Loud fans, max speed | - | Aggressive cooling |
| balanced | **Used** | - | Quieter, responsive |
| low-power | - | **Used** | Minimal fan activity |

The `balanced` profile on AC provides good performance with quieter fans compared to `performance` mode.

### TLP Commands

```bash
# Full status
sudo tlp-stat

# Battery info
sudo tlp-stat -b

# Processor info
sudo tlp-stat -p

# USB devices
sudo tlp-stat -u

# Force performance mode (temporary, for heavy workloads)
sudo tlp performance

# Return to automatic mode (AC/battery auto-switching)
sudo tlp start

# Force full charge (for travel)
sudo tlp fullcharge
```

## Platform Profiles

ThinkPads support platform performance profiles.

### Check Current Profile

```bash
cat /sys/firmware/acpi/platform_profile
```

Note: `power-profiles-daemon` is masked because TLP manages platform profiles.

### Available Profiles

```bash
cat /sys/firmware/acpi/platform_profile_choices
# low-power balanced performance
```

| Profile | Description |
|---------|-------------|
| low-power | Maximum battery life |
| balanced | Default balance |
| performance | Maximum performance |

### Set Profile

TLP manages profiles automatically based on power source. To override temporarily:

```bash
# Force performance mode
sudo tlp performance

# Return to automatic (AC=balanced, BAT=low-power)
sudo tlp start

# Manual sysfs override (not persistent)
echo balanced | sudo tee /sys/firmware/acpi/platform_profile
```

## Suspend Modes

### Current Mode

```bash
cat /sys/power/mem_sleep
# [s2idle] deep
```

This system uses **s2idle** (Modern Standby / S0ix).

### Suspend Types

| Mode | Description |
|------|-------------|
| s2idle | Modern standby, quick wake |
| deep | Traditional S3 suspend |

### Suspend Commands

```bash
# Suspend
systemctl suspend

# Check suspend stats
cat /sys/kernel/debug/suspend_stats
```

## Lid Switch Behavior

**File:** `/etc/systemd/logind.conf`

```ini
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

| Setting | Value | Description |
|---------|-------|-------------|
| HandleLidSwitch | suspend | Suspend on lid close (battery) |
| HandleLidSwitchExternalPower | ignore | Don't suspend on AC |
| HandleLidSwitchDocked | ignore | Don't suspend when docked |

## Fan Control

### Monitor Fans

```bash
sensors | grep fan
# fan1:        7172 RPM
# fan2:        6592 RPM
```

### Fan Control via thinkpad_acpi

```bash
# Check if fan control is available
cat /proc/acpi/ibm/fan

# Enable manual control (use with caution!)
echo "level auto" | sudo tee /proc/acpi/ibm/fan

# Set specific level (0-7, auto, full-speed)
echo "level 4" | sudo tee /proc/acpi/ibm/fan
```

**Warning:** Manual fan control can cause overheating. Leave on `auto` for normal use.

## Thermal Management

### Monitor Temperatures

```bash
sensors
```

Key thermal zones:
- **coretemp**: CPU package and individual cores
- **thinkpad**: Chassis and fan monitoring
- **nvme**: SSD temperature

### Throttling

The system will throttle if temperatures exceed:
- 100°C (CPU thermal limit)
- ~80°C (SSD thermal limit)

```bash
# Check for thermal throttling
journalctl -k | grep -i thermal
journalctl -k | grep -i throttl
```

## Power Consumption

### Monitor Power Usage

```bash
# Current power draw
cat /sys/class/power_supply/BAT0/power_now
# Value in microwatts

# Or via upower
upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "energy-rate"

# Via TLP
sudo tlp-stat -b | grep "power"
```

### Typical Power Draw

| State | Power |
|-------|-------|
| Idle (screen on) | 5-8W |
| Light use | 10-15W |
| Heavy load | 30-45W |
| Charging overhead | +10-15W |

## USB Power

### USB Autosuspend

TLP enables USB autosuspend to save power.

```bash
# Check USB power status
sudo tlp-stat -u
```

### Exclude Devices

Some devices shouldn't autosuspend:

```bash
# In /etc/tlp.conf
USB_EXCLUDE_BTUSB=1          # Bluetooth
USB_EXCLUDE_PHONE=1          # Phones
USB_EXCLUDE_WWAN=1           # WWAN modems

# Exclude by ID
USB_DENYLIST="1234:5678"
```

## Quick Reference

```bash
# Battery status
upower -i /org/freedesktop/UPower/devices/battery_BAT0
sudo tlp-stat -b

# Current platform profile
cat /sys/firmware/acpi/platform_profile

# TLP status and control
sudo tlp-stat
sudo tlp start           # Auto mode (uses config)
sudo tlp performance     # Force performance (temporary)
sudo tlp fullcharge      # Charge to 100% (for travel)

# Temperatures and fans
sensors
cat /proc/acpi/ibm/fan

# Edit custom TLP settings
sudo nano /etc/tlp.d/10-thinkpad.conf

# Suspend
systemctl suspend
```

## Related

- [../systemd/04-POWER-MANAGEMENT.md](../systemd/04-POWER-MANAGEMENT.md) - TLP service
- [01-OVERVIEW](./01-OVERVIEW.md) - Hardware specs
