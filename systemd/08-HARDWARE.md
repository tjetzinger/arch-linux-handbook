# 08 - Hardware Services

Hardware-specific services and device management.

## Service Summary

| Service | Purpose | Status |
|---------|---------|--------|
| logid | Logitech device config | Running |
| bluetooth | Bluetooth stack | Running |
| cups | Printing | Running |
| acpid | ACPI events | Running |
| udisks2 | Disk management | Running |

## logid (Logitech)

Configuration daemon for Logitech devices.

### Status

```bash
systemctl status logid
```

### Current Device

```
M585/M590 Multi-Device Mouse on /dev/hidraw3:255
```

### Configuration

**File:** `/etc/logid.cfg`

Example configuration:
```
devices: ({
    name: "M585/M590 Multi-Device Mouse";
    smartshift: {
        on: true;
        threshold: 30;
    };
    dpi: 1000;
    buttons: (
        {
            cid: 0xc3;
            action = {
                type: "Gestures";
                gestures: (
                    {
                        direction: "Up";
                        mode: "OnRelease";
                        action = {
                            type: "Keypress";
                            keys: ["KEY_LEFTMETA"];
                        };
                    }
                );
            };
        }
    );
});
```

### Commands

```bash
# Restart to apply config changes
sudo systemctl restart logid

# View logs
journalctl -u logid
```

## Bluetooth

BlueZ Bluetooth stack.

### Status

```bash
systemctl status bluetooth
bluetoothctl show
```

### Commands

```bash
# Interactive mode
bluetoothctl

# Power on/off
bluetoothctl power on
bluetoothctl power off

# Scan for devices
bluetoothctl scan on

# Pair device
bluetoothctl pair <MAC>

# Connect
bluetoothctl connect <MAC>

# Trust device (auto-connect)
bluetoothctl trust <MAC>

# List devices
bluetoothctl devices
```

### Configuration

**File:** `/etc/bluetooth/main.conf`

```ini
[General]
AutoEnable=true
FastConnectable=true

[Policy]
AutoEnable=true
```

### Restart

```bash
sudo systemctl restart bluetooth
```

## CUPS (Printing)

Common Unix Printing System.

### Status

```bash
systemctl status cups
```

### Web Interface

```
http://localhost:631
```

### Commands

```bash
# List printers
lpstat -p

# Print file
lpr -P <printer> file.pdf

# Cancel job
cancel <job-id>

# Queue status
lpq
```

### Socket Activation

CUPS uses socket activation:
```bash
systemctl status cups.socket
systemctl status cups.path
```

Only starts when printing is needed.

## acpid

ACPI event daemon (power button, lid, etc.).

### Status

```bash
systemctl status acpid
```

### Events

Handles:
- Power button press
- Lid open/close
- AC adapter events
- Special keys

### Configuration

**Directory:** `/etc/acpi/`

```
/etc/acpi/
├── events/           # Event definitions
└── actions/          # Action scripts
```

### Logs

```bash
journalctl -u acpid
```

Note: Most ACPI handling is done by systemd-logind on modern systems.

## udisks2

Disk management daemon.

### Status

```bash
systemctl status udisks2
```

### Purpose

- Automatic USB drive mounting
- Disk information queries
- Drive management for file managers

### Commands

```bash
# List drives
udisksctl status

# Mount drive
udisksctl mount -b /dev/sdb1

# Unmount drive
udisksctl unmount -b /dev/sdb1

# Power off drive
udisksctl power-off -b /dev/sdb

# Drive info
udisksctl info -b /dev/sda
```

### Configuration

**File:** `/etc/udisks2/udisks2.conf`

## USB Autosuspend

Managed by TLP for power savings.

### Check Status

```bash
# TLP USB settings
sudo tlp-stat -u
```

### Configuration

In `/etc/tlp.conf`:
```bash
USB_AUTOSUSPEND=1
USB_EXCLUDE_BTUSB=1      # Don't suspend Bluetooth
USB_EXCLUDE_PHONE=1      # Don't suspend phones
```

## Firmware Updates

fwupd handles firmware updates.

### Check for Updates

```bash
fwupdmgr refresh
fwupdmgr get-updates
```

### Apply Updates

```bash
fwupdmgr update
```

### List Devices

```bash
fwupdmgr get-devices
```

## Sensors

lm_sensors for temperature/fan monitoring.

### Read Sensors

```bash
sensors
```

### Detect Sensors

```bash
sudo sensors-detect
```

## Hardware Information

### System Info

```bash
# CPU
lscpu

# Memory
free -h

# Disks
lsblk

# PCI devices
lspci

# USB devices
lsusb

# Full hardware
sudo dmidecode
inxi -F   # If installed
```

## Quick Reference

```bash
# Logitech
systemctl status logid
sudo systemctl restart logid

# Bluetooth
bluetoothctl
bluetoothctl power on
bluetoothctl devices

# Printing
systemctl status cups
lpstat -p

# Disks
udisksctl status
udisksctl mount -b /dev/sdb1

# Firmware
fwupdmgr get-updates

# Sensors
sensors
```

## Related

- [04-POWER-MANAGEMENT](./04-POWER-MANAGEMENT.md) - Power features
- [07-DESKTOP-SERVICES](./07-DESKTOP-SERVICES.md) - Audio services
- [02-CORE-SERVICES](./02-CORE-SERVICES.md) - udev
