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

## Battery Replacement

### When to Replace

Consider battery replacement when:
- Battery health drops below **80%** (current: 86%)
- Charge cycles exceed **300-400** (current: 110)
- Runtime becomes insufficient for your usage pattern
- Battery no longer holds charge effectively

**Current Status**: Battery at 86% health with 110 cycles shows **higher degradation than typical**. Monitor monthly and replace when health drops below 80%.

### Check Battery Health

```bash
# Full battery status
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Quick health check
upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "capacity|cycle|energy-full"

# TLP battery report
sudo tlp-stat -b

# Calculate health percentage
echo "scale=2; $(cat /sys/class/power_supply/BAT0/energy_full) / $(cat /sys/class/power_supply/BAT0/energy_full_design) * 100" | bc
```

### Compatible Batteries

All compatible with ThinkPad X1 Carbon Gen 9, 10, and 11:

| Part Number | Type | Notes |
|-------------|------|-------|
| **5B10W13973** | OEM | Current battery model |
| **5B10W13975** | OEM | Same specs, widely available |
| **5B11M90057** | OEM | Newer revision |
| **5B11M90058** | OEM | Newer revision |
| **L20C4P71** | Chemistry | Battery chemistry designation |
| **L20M4P71** | Chemistry | Battery chemistry designation |

**Specifications**:
- Capacity: 57 Wh (3690 mAh)
- Voltage: 15.44V
- Cells: 4-cell Li-poly
- Chemistry: Lithium Polymer

### Recommended Vendors

#### Genuine OEM (Recommended)

| Vendor | Price | Part Number | Notes |
|--------|-------|-------------|-------|
| **CDW** | **$91.99** | L20C4P71-TMC | Best price, meets OEM specs |
| **iFixit** | $114.99 | 5B10W13975 | Includes tools, US shipping only |
| **LaptopBatteryExpress** | $115-125 | Multiple | 1 year warranty |

**Links**:
- CDW: https://www.cdw.com/product/total-micro-battery-lenovo-thinkpad-x1-carbon-11th-gen-4-cell-57whr/7459024
- iFixit: https://www.ifixit.com/products/5b10w13975-lenovo-thinkpad-x1-carbon-9th-gen-battery

#### Third-Party (Not Recommended)

| Vendor | Price | Notes |
|--------|-------|-------|
| Amazon (JIAZIJIA) | $50-80 | Quality concerns, shorter lifespan |
| eBay | $60-100 | Verify seller reputation |

**Recommendation**: Use genuine OEM batteries for best longevity and compatibility.

### Tools Required

- **Phillips-head screwdriver** (small, #0 or #00)
- **Plastic spudger** or prying tool
- **Anti-static wrist strap** (recommended)

### Replacement Procedure

**Estimated Time**: 15-30 minutes

#### Preparation

```bash
# 1. Check current battery status
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# 2. Ensure battery is not charging
# Unplug AC adapter

# 3. Power down completely
sudo systemctl poweroff
```

**Important**:
- Work on clean, flat, static-free surface
- Disconnect all external devices (USB, displays, etc.)
- Remove AC adapter before opening

#### Step-by-Step

**1. Remove Bottom Cover**

- Place laptop upside down on soft surface
- Loosen **7 captive screws** (Phillips #0)
  - Screws stay attached to cover, they don't come out
- Use plastic spudger to gently pry cover at rear edge
- Work around edges to release clips
- Slide cover back and lift off

**2. Disconnect Battery**

- Locate battery connector (ribbon cable near center)
- Use plastic spudger to carefully lift connector tab
- Gently pull connector away from socket
- **CRITICAL**: Only use plastic tools near battery

**3. Remove Old Battery**

- Remove 5 small Phillips screws securing battery
- Carefully lift battery out of chassis
- Avoid bending or puncturing battery

**4. Install New Battery**

- Place new battery in position
- Align screw holes
- Secure with 5 Phillips screws (do not overtighten)
- Connect battery ribbon cable
  - Align connector carefully
  - Press firmly until seated

**5. Reassemble**

- Verify battery connector is secure
- Replace bottom cover
  - Slide front edge under lip first
  - Press down around edges to engage clips
- Tighten 7 captive screws evenly

**6. Verify**

```bash
# Power on and check battery is recognized
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Verify capacity
cat /sys/class/power_supply/BAT0/energy_full_design
# Should show ~57050000 (57 Wh)

# Check cycle count (should be 0 or low)
cat /sys/class/power_supply/BAT0/cycle_count
```

### Post-Replacement

**First charge**:
1. Fully drain new battery to ~5%
2. Charge to 100% uninterrupted
3. Repeat 2-3 times to calibrate

**Update docs**:
```bash
# Update hardware/01-OVERVIEW.md with:
# - New battery install date
# - Initial cycle count
# - Design capacity verification
```

**Re-enable charge thresholds**:
```bash
# Verify TLP thresholds active
sudo tlp-stat -b | grep -A2 "charge thresholds"
```

### Battery Health Monitoring

**Manual check** (monthly):
```bash
sudo tlp-stat -b | grep -E "capacity|cycle"
```

**Automated monitoring** (optional):

Create `~/.local/bin/battery-health-check`:
```bash
#!/bin/bash
# Battery health monitoring script

THRESHOLD=80
HEALTH=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | \
    grep capacity | awk '{print $2}' | sed 's/%//')

if (( $(echo "$HEALTH < $THRESHOLD" | bc -l) )); then
    notify-send -u critical "Battery Health Warning" \
        "Battery at ${HEALTH}% health - consider replacement"
    echo "$(date): Battery health at ${HEALTH}%" >> ~/.local/log/battery-health.log
fi
```

Make executable:
```bash
chmod +x ~/.local/bin/battery-health-check
```

**Run weekly via systemd timer** (optional):

Create `~/.config/systemd/user/battery-health.service`:
```ini
[Unit]
Description=Battery health check

[Service]
Type=oneshot
ExecStart=%h/.local/bin/battery-health-check
```

Create `~/.config/systemd/user/battery-health.timer`:
```ini
[Unit]
Description=Weekly battery health check

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

Enable:
```bash
systemctl --user enable --now battery-health.timer
```

### Troubleshooting

**Battery not recognized**:
```bash
# Check connection
cat /sys/class/power_supply/BAT0/present
# Should return: 1

# Verify driver loaded
dmesg | grep -i battery
```

**Incorrect capacity**:
- Run 2-3 full charge/discharge cycles
- Battery may need calibration

**Won't charge past threshold**:
- Verify TLP thresholds: `sudo tlp-stat -b`
- Temporarily disable: `sudo tlp fullcharge BAT0`

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

# Exclude eMeet Luna from autosuspend (sends KEY_SLEEP on disconnect)
USB_DENYLIST="328f:2001"
```

### Key Settings Explained

| Setting | Value | Effect |
|---------|-------|--------|
| PCIE_ASPM_ON_BAT | powersupersave | Enables L1.2 substates, critical for deep C-states (C8+) |
| CPU_BOOST_ON_BAT | 0 | Disables turbo boost, saves 2-3W under load |
| INTEL_GPU_MAX_FREQ_ON_BAT | 800 | Caps GPU at 800 MHz (vs 1500 MHz default) |
| CPU_ENERGY_PERF_POLICY_ON_BAT | power | Most aggressive CPU power saving |
| USB_DENYLIST | 328f:2001 | Prevents eMeet Luna from autosuspend (KEY_SLEEP issue) |

**Note:** `PCIE_ASPM_ON_BAT=powersupersave` requires a **reboot** to take effect. Using `powersave` instead can prevent reaching deep package C-states.

### Platform Profile Explanation

| Profile | On AC | On Battery | Fan Behavior |
|---------|-------|------------|--------------|
| performance | Loud fans, max speed | - | Aggressive cooling |
| balanced | **Used** | - | Quieter, responsive |
| low-power | - | **Used** | Minimal fan activity |

The `balanced` profile on AC provides good performance with quieter fans compared to `performance` mode.

### Runtime PM Driver Denylist

**File:** `/etc/tlp.conf`

```ini
RUNTIME_PM_DRIVER_DENYLIST="mei_me nouveau radeon xhci_hcd"
```

Drivers in the denylist are excluded from runtime power management to prevent issues:

| Driver | Purpose | Why Excluded |
|--------|---------|--------------|
| `mei_me` | Intel Management Engine | Can cause system instability with PM |
| `nouveau` | Open-source NVIDIA driver | GPU PM can cause hangs |
| `radeon` | AMD GPU driver | GPU PM can cause hangs |
| `xhci_hcd` | USB host controller | Prevents USB device wake issues |

**Check current status:**
```bash
sudo tlp-stat -e | grep "Driver denylist"
```

**Note:** Removing `xhci_hcd` from the denylist saves power but may cause USB devices to not wake properly. Keep the default for reliability.

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

# PCI devices and runtime PM
sudo tlp-stat -e

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

Custom logind configuration to prevent unwanted suspends when using external monitors with lid closed.

**File:** `/etc/systemd/logind.conf.d/10-lid-switch.conf`

```ini
[Login]
# When on external power (AC), don't suspend on lid close
# This prevents unwanted suspends when docked but monitors go to DPMS off
# (USB-C/Thunderbolt docks don't reliably trigger "Docked" status)
HandleLidSwitchExternalPower=ignore

# When properly detected as docked (multiple displays), also ignore
HandleLidSwitchDocked=ignore
```

| Setting | Value | Description |
|---------|-------|-------------|
| HandleLidSwitch | suspend (default) | Suspend on lid close (battery) |
| HandleLidSwitchExternalPower | ignore | Don't suspend on AC power |
| HandleLidSwitchDocked | ignore | Don't suspend when docked |

### Why Use a Drop-in File?

Using `/etc/systemd/logind.conf.d/10-lid-switch.conf` instead of editing `/etc/systemd/logind.conf`:
- Survives package updates
- Clear separation of custom settings
- Easy to disable (just remove the file)

### Docked Detection

logind considers the system "docked" when:
- Connected to a traditional dock, OR
- More than one display is connected

```bash
# Check current docked status
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager Docked
# b true = docked, b false = not docked
```

### Apply Changes

```bash
sudo systemctl restart systemd-logind
# Note: This will terminate your current session!
# Alternative: reboot
```

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
# In /etc/tlp.d/10-thinkpad.conf
USB_EXCLUDE_BTUSB=1          # Bluetooth
USB_EXCLUDE_PHONE=1          # Phones
USB_EXCLUDE_WWAN=1           # WWAN modems

# Exclude by ID (find with lsusb)
USB_DENYLIST="328f:2001"     # eMeet Luna speakerphone
```

### USB Denylist: eMeet Luna Issue

The eMeet Luna speakerphone (ID `328f:2001`) has a HID Consumer Control interface that sends `KEY_SLEEP` when the USB connection drops. If TLP autosuspends the device, this triggers system suspend.

**Symptoms:**
- System suspends unexpectedly while idle
- USB disconnect logged immediately before suspend
- `journalctl -b` shows `usb 3-3.3.3.4.1: USB disconnect` then `systemd-logind: Suspending...`

**Solution:**
```bash
# Add to /etc/tlp.d/10-thinkpad.conf
USB_DENYLIST="328f:2001"

# Apply
sudo tlp start

# Verify device is excluded
sudo tlp-stat -u | grep eMeet
# Should show: control = on (not auto)
```

**Find device ID:**
```bash
lsusb | grep -i emeet
# Bus 003 Device 014: ID 328f:2001 eMeet eMeet Luna
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
