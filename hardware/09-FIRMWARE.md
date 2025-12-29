# 09 - Firmware

BIOS and firmware updates via fwupd.

## Current Firmware

### BIOS Information

```bash
sudo dmidecode -t bios
```

| Field | Value |
|-------|-------|
| Vendor | LENOVO |
| Version | N3XET63W (1.38) |
| Release Date | 2025-10-08 |
| EC Firmware | 1.22 |

### Dock Firmware

| Device | Version |
|--------|---------|
| ThinkPad USB-C Dock Gen2 (40AS) | 5.05.00 |

### Check BIOS Version

```bash
# Via dmidecode
sudo dmidecode -t bios | grep -E "Version|Release"

# Via fwupdmgr
fwupdmgr get-devices | head -30
```

## fwupd

Linux Vendor Firmware Service (LVFS) client for firmware updates.

### Status

```bash
fwupdmgr get-devices
```

### Check for Updates

```bash
# Refresh metadata
fwupdmgr refresh

# Check for updates
fwupdmgr get-updates
```

### Apply Updates

```bash
# Download and install
fwupdmgr update

# This will prompt for reboot
```

### Update History

```bash
fwupdmgr get-history
```

## Firmware Update Log

### 2025-12-24: BIOS 1.22 → 1.38

**Reason:** Dock ethernet not working on hot-plug (USB 3.0 devices not enumerating)

**Updates Applied:**

| Component | Previous | New | Status |
|-----------|----------|-----|--------|
| System Firmware (BIOS) | 1.22 | 1.38 | Success |
| Embedded Controller | 1.17 | 1.19 | Pending reboot |
| ThinkPad USB-C Dock Gen2 | 5.04.05 | 5.05.00 | Success |

**Procedure:**
```bash
# Install fwupd
sudo pacman -S fwupd

# Refresh and check updates
fwupdmgr refresh
fwupdmgr get-updates

# Apply updates
fwupdmgr update

# Reboot to complete
systemctl reboot
```

**Release Notes (BIOS 1.38):**
- Enhancement to address security vulnerabilities (CVE-2025-10237, CVE-2025-2295)
- Updated Diagnostics module to version 04.43.000
- Note: Cannot rollback to versions before 1.38

**Relevant Fix (BIOS 1.25):**
> Fixed an issue where the system might not recognize Realtek USB Ethernet
> device connected to ThinkPad USB-C Dock Gen 2 during Docking/Monitor detection.

**Result:**
- Dock ethernet works when booting with dock connected
- Hot-plug still does not enumerate USB 3.0 devices (Type-C physical layer limitation)

**Known Issue - USB 3.0 Hot-Plug:**
The dock's USB 3.0 hub (containing ethernet, USB 3.0 ports) does not enumerate
when hot-plugging the dock. Only USB 2.0 devices enumerate.

**Hot-Plug Analysis (2025-12-24):**
| Comparison | Boot | Hot-Plug |
|------------|------|----------|
| typec port | port0-partner | **port1-partner** |
| USB 3.0 bus | Bus 2 (2-1, 20Gbps) | **EMPTY** |
| Dock location | 2-1 (SuperSpeed) | **3-3 (High-Speed)** |
| Ethernet | Present | **Missing** |

On disconnect, both Thunderbolt USB buses report:
```
usb usb1: root hub lost power or was reset
usb usb2: root hub lost power or was reset
```

But on reconnect, the dock enumerates on the internal xHCI controller
(bus 3-3) instead of Thunderbolt (bus 2-1). The typec/ucsi driver
fails to re-establish SuperSpeed lane negotiation.

**BIOS Settings Investigation:**
- X1 Carbon Gen 11 has no user-configurable Thunderbolt/USB-C settings
- "Thunderbolt BIOS Assist Mode" not available (removed in newer models)
- "Security Level" and "Pre Boot Support" options not present
- Issue cannot be resolved via BIOS configuration

**Root Cause Confirmed:**
- Hot-plug works on Windows but not Linux = Linux driver issue, not hardware
- Linux Type-C/UCSI driver timing issue with SuperSpeed lane negotiation
- Known kernel issue affecting multiple USB-C docks

**References:**
- Red Hat Bugzilla #2248484: UCSI driver bug
- Arch Linux Forum: https://bbs.archlinux.org/viewtopic.php?id=308325
- Kernel Bugzilla: https://bugzilla.kernel.org/show_bug.cgi?id=220904

Workarounds:
1. Boot with dock connected (recommended)
2. Plug dock in AFTER login screen appears (reported reliable)
3. Suspend/resume may trigger re-enumeration
4. Use USB 2.0 ethernet adapter as fallback

## Supported Devices

Devices that can be updated via fwupd:

| Device | Component |
|--------|-----------|
| System Firmware | BIOS/UEFI |
| EC Firmware | Embedded Controller |
| NVMe | SSD firmware (KIOXIA KXG8AZNV2T04) |
| Thunderbolt | Controller firmware |
| ThinkPad USB-C Dock Gen2 | MST Hub (DisplayPort) |
| Intel Management Engine | ME firmware |
| UEFI dbx | Secure Boot revocation database |

## ThinkPad BIOS Update

### Via fwupd (Recommended)

```bash
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update
```

### Via Lenovo

1. Download from [Lenovo Support](https://support.lenovo.com)
2. Create bootable USB with the ISO
3. Boot and follow instructions

### BIOS Settings

Access BIOS by pressing **F1** during boot (or Enter, then F1).

Important settings:
- Secure Boot (enabled for Windows VMs)
- Virtualization (VT-x, VT-d enabled)
- Thunderbolt security
- Boot order

## Embedded Controller (EC)

The EC manages:
- Power management
- Keyboard
- Fans
- Battery charging
- ThinkPad buttons

### Check EC Version

```bash
sudo dmidecode -t bios | grep -i "firmware revision"
# Or
fwupdmgr get-devices | grep -A 5 "Embedded Controller"
```

### Update EC

EC updates are included with BIOS updates via fwupd.

## NVMe Firmware

### Check Current Version

```bash
sudo nvme id-ctrl /dev/nvme0 | grep -i fr
# Or
fwupdmgr get-devices | grep -A 10 "NVMe"
```

### Update NVMe

If available through fwupd:
```bash
fwupdmgr update
```

**Warning:** NVMe firmware updates require power (AC adapter).

## Thunderbolt Firmware

### Check Version

```bash
boltctl list
fwupdmgr get-devices | grep -A 10 "Thunderbolt"
```

### Update

Included in fwupd updates.

## Security

### Secure Boot

Check status:
```bash
mokutil --sb-state
# SecureBoot enabled/disabled
```

### TPM

```bash
# Check TPM
cat /sys/class/tpm/tpm0/tpm_version_major
```

## BIOS Recovery

If BIOS update fails:

1. ThinkPads have BIOS recovery via USB
2. Create recovery USB from Lenovo
3. Follow Lenovo's recovery procedure

### Emergency Recovery

Press and hold **F1** during power-on to access BIOS recovery options.

## Intel Microcode

CPU microcode updates are separate from BIOS.

### Check Version

```bash
dmesg | grep microcode
# Or
cat /proc/cpuinfo | grep microcode
```

### Install Updates

```bash
sudo pacman -S intel-ucode
```

Already configured in systemd-boot:
```
initrd  /intel-ucode.img
```

## Firmware Security

### Check Firmware Security

```bash
fwupdmgr security
```

Shows HSI (Host Security ID) level.

### HSI Levels

| Level | Security |
|-------|----------|
| HSI:0 | No protection |
| HSI:1 | Basic protection |
| HSI:2 | Hardware security |
| HSI:3 | Verified boot |
| HSI:4 | Runtime protection |

## Update Schedule

### Recommendations

1. **Check monthly** for security updates
2. **Read release notes** before updating
3. **Backup important data** before BIOS updates
4. **Ensure AC power** during updates
5. **Don't interrupt** firmware updates

### Automatic Checks

fwupd can notify of updates:
```bash
# Enable update notifications
systemctl enable --now fwupd-refresh.timer
```

## Troubleshooting

### fwupd Errors

```bash
# Debug mode
fwupdmgr get-updates -v

# Check logs
journalctl -u fwupd
```

### Update Fails

```bash
# Check system requirements
fwupdmgr get-devices

# Ensure AC power
# Ensure battery > 30%

# Try again
fwupdmgr update
```

### BIOS Won't Update

1. Check Lenovo website for known issues
2. Try USB-based update method
3. Contact Lenovo support

## Quick Reference

```bash
# Check BIOS version
sudo dmidecode -t bios | grep Version

# List updatable devices
fwupdmgr get-devices

# Check for updates
fwupdmgr refresh
fwupdmgr get-updates

# Apply updates
fwupdmgr update

# Security status
fwupdmgr security

# Update history
fwupdmgr get-history
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - System specifications
- [02-POWER-BATTERY](./02-POWER-BATTERY.md) - Power requirements for updates
