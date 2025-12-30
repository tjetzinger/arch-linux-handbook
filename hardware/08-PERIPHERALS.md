# 08 - Peripherals

External devices and their configuration.

## Connected Devices

```bash
lsusb
```

| Device | Vendor | Purpose |
|--------|--------|---------|
| Logitech M585/M590 | Logitech | Wireless mouse |
| Logitech MX Master 3S | Logitech | Wireless mouse |
| Yubikey 4/5 | Yubico | Security key |
| Chicony Camera | Chicony | Built-in webcam |

## Logitech Mice

### Devices

Two Logitech mice configured via **logid** (Logiops daemon):

1. **MX Master 3S** - Premium wireless mouse
2. **M585/M590** - Compact multi-device mouse

### logid Service

```bash
systemctl status logid
```

### Bluetooth Startup Fix

Logitech devices connect via Bluetooth after boot. Two issues can prevent logid from configuring devices:

1. **Boot timing** - logid starts before Bluetooth devices connect
2. **bluez 5.77+ bug** - Device times out during initial HID configuration

**Symptom:**
```
[WARN] Error adding device /dev/hidraw7: Device timed out
[WARN] Failed to add device /dev/hidraw5 after 5 tries. Treating as failure.
```

**Fix 1: Systemd override** - Wait for Bluetooth service

**File:** `/etc/systemd/system/logid.service.d/bluetooth-wait.conf`
```ini
[Unit]
# Wait for Bluetooth to be ready before starting logid
After=bluetooth.target
Wants=bluetooth.target

[Service]
# Restart on failure to handle timing issues
Restart=on-failure
RestartSec=5
```

**Fix 2: udev rule** - Restart logid when Logitech device connects

This handles the bluez 5.77+ timing issue where devices timeout during initial connection.

**File:** `/etc/udev/rules.d/99-logitech-logid-restart.rules`
```udev
# Restart logid when Logitech Bluetooth HID devices connect
# Fixes bluez 5.77+ timing issue where logid fails to configure device
ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", \
  RUN+="/bin/bash -c 'sleep 2 && systemctl restart logid &'"
```

**Apply:**
```bash
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo systemctl restart logid
```

**Verify after reboot:**
```bash
journalctl -b -u logid | grep -E "found|WARN|ERROR"
```

### Configuration

**File:** `/etc/logid.cfg`

#### MX Master 3S

```cfg
{
  name: "MX Master 3S";
  smartshift: { on: true; threshold: 20; };
  hiresscroll: { hires: true; invert: true; target: false; };
  dpi: 1500;  // max 4000

  buttons: (
    { cid: 0x56; action = { type: "Keypress"; keys: ["KEY_FORWARD"]; }; },
    { cid: 0x53; action = { type: "Keypress"; keys: ["KEY_BACK"]; }; },
    { cid: 0xc4; action = { type = "ToggleSmartshift"; }; },
    {
      cid: 0xc3;  // Gesture button
      action = {
        type: "Gestures";
        gestures: (
          { direction: "Up"; mode: "OnRelease";
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_LEFTCTRL", "KEY_UP"]; }; },
          { direction: "Down"; mode: "OnRelease";
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_LEFTCTRL", "KEY_DOWN"]; }; },
          { direction: "Left"; mode: "OnRelease";
            action = { type: "KeyPress"; keys: ["KEY_LEFTMETA", "KEY_LEFTCTRL", "KEY_LEFT"]; }; },
          { direction: "Right"; mode: "OnRelease";
            action = { type: "KeyPress"; keys: ["KEY_LEFTMETA", "KEY_LEFTCTRL", "KEY_RIGHT"]; }; }
        );
      };
    }
  );

  thumbwheel: {
    divert: true;
    invert: false;
    left: { threshold: 100; interval: 1;
      action = { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; };
    right: { threshold: 100; interval: 1;
      action = { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; };
  };
}
```

#### M585/M590

```cfg
{
  name: "M585/M590 Multi-Device Mouse";
  hiresscroll: { hires: true; invert: true; target: false; };
  dpi: 3500;  // max 4000

  buttons: (
    { cid: 0x56; action = { type: "Keypress"; keys: ["KEY_FORWARD"]; }; },
    { cid: 0x53; action = { type: "Keypress"; keys: ["KEY_BACK"]; }; },
    { cid: 0x5b; action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_LEFTCTRL", "KEY_LEFT"]; }; },
    { cid: 0x5d; action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_LEFTCTRL", "KEY_RIGHT"]; }; }
  );
}
```

### Features Configured

| Feature | MX Master 3S | M585/M590 |
|---------|--------------|-----------|
| DPI | 1500 | 3500 |
| SmartShift | Yes | No |
| HiRes Scroll | Yes | Yes |
| Gestures | Yes | No |
| Thumb wheel | Volume | N/A |

### Volume Step Configuration

The MX Master 3S thumbwheel sends `XF86AudioRaiseVolume`/`XF86AudioLowerVolume` keys. Volume step is configured in Hyprland keybindings.

**File:** `~/.config/hypr/conf/keybindings/custom.conf`

```bash
bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +1%  # 1% step
bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -1%  # 1% step
```

Change `+1%`/`-1%` to desired step (e.g., `+5%` for larger increments).

### Apply Configuration

```bash
sudo systemctl restart logid
```

### Logs

```bash
journalctl -u logid
```

### Finding Button CIDs

```bash
# Run logid in debug mode
sudo logid -v

# Press buttons to see CID values in logs
```

## Yubikey

### Device Info

```bash
lsusb | grep Yubico
```

```
Yubico.com Yubikey 4/5 OTP+U2F+CCID
```

### Features

| Feature | Description |
|---------|-------------|
| OTP | One-time passwords |
| U2F/FIDO2 | WebAuthn/FIDO |
| PIV | Smart card |
| OpenPGP | GPG keys |
| OATH | TOTP/HOTP |

### ykman (Yubikey Manager)

```bash
# Install
sudo pacman -S yubikey-manager

# List devices
ykman list

# Device info
ykman info

# Configure OTP slots
ykman otp info
```

### SSH Authentication

```bash
# Generate SSH key on Yubikey (PIV)
ykman piv generate-key 9a pubkey.pem
ykman piv generate-certificate -s "SSH Key" 9a pubkey.pem

# Or use GPG key
# Configure gpg-agent for SSH
```

### FIDO2/WebAuthn

Works automatically in browsers for:
- GitHub
- Google
- Microsoft
- Many others

### Troubleshooting

```bash
# Check udev rules
cat /usr/lib/udev/rules.d/69-yubikey.rules

# Test device
ykman info
```

## USB Hubs/Docks

### ThinkPad USB-C Dock Gen2 (40AS)

Primary docking station providing ethernet, USB ports, DisplayPort, and audio.

**Firmware:** 5.05.00 (latest via fwupd)

**USB Devices:**
| ID | Device | USB Bus |
|----|--------|---------|
| 17ef:a391 | USB3.1 Hub | USB 3.0 |
| 17ef:a387 | USB-C Dock Ethernet | USB 3.0 |
| 17ef:a392 | USB2.0 Hub | USB 2.0 |
| 17ef:a396 | USB Audio | USB 2.0 |
| 17ef:a38f | Dock Controller | USB 2.0 |

**Ethernet Driver:**

The dock ethernet uses the **r8152** driver (Realtek RTL8153 chipset).

```bash
# Check driver
readlink /sys/class/net/enp0s13f0u3u1/device/driver | xargs basename
# Output: r8152
```

**Known Issue: USB 3.0 Hot-Plug Does Not Work (Kernel Bug)**

**Kernel Bug:** https://bugzilla.kernel.org/show_bug.cgi?id=220904

The dock's USB 3.0 devices (ethernet, USB 3.0 ports) do not enumerate when hot-plugging the dock. Only USB 2.0 devices (audio, hub, controller) enumerate.

**Root Cause:** Type-C physical layer negotiation issue. The laptop and dock do not properly re-negotiate SuperSpeed (USB 3.0) lanes on hot-plug. This is a limitation at the hardware/firmware level, not a driver issue.

**Symptoms on hot-plug:**
- `lsusb` shows only USB 2.0 dock devices (17ef:a392, 17ef:a396, 17ef:a38f)
- USB 3.0 devices missing (17ef:a391, 17ef:a387)
- Ethernet interface does not appear
- `dmesg` shows "new high-speed USB device" but no "SuperSpeed" messages

**Investigation (2025-12-24):**
- BIOS updated from 1.22 → 1.38 (fixed cold boot detection)
- Dock firmware at 5.05.00 (latest)
- USB autosuspend disabled - no effect
- xHCI reset - no effect
- UCSI driver shows "possible UCSI driver bug 4" in dmesg
- BIOS Thunderbolt settings not available on X1 Carbon Gen 11 (no user-configurable options)
- "Thunderbolt BIOS Assist Mode" removed in newer models (native kernel support)
- Hot-plug works on Windows but not Linux = Linux driver issue, not hardware

**Root Cause:** Linux Type-C/UCSI driver timing issue. At boot, full USB-C negotiation
happens during hardware init. On hot-plug, the typec driver doesn't properly
re-negotiate SuperSpeed lanes. This is a known kernel issue affecting multiple
USB-C docks on Linux.

**Hot-Plug Analysis (2025-12-24):**
| State | typec port | USB 3.0 bus | Dock location | Ethernet |
|-------|------------|-------------|---------------|----------|
| Boot | port0-partner | Bus 2 (2-1, 20Gbps) | 2-1 (SuperSpeed) | Present |
| Hot-Plug | port1-partner | EMPTY | 3-3 (High-Speed) | Missing |

dmesg on reconnect shows:
```
usb usb1: root hub lost power or was reset
usb usb2: root hub lost power or was reset
```
The Thunderbolt USB buses reset but the dock falls back to the internal xHCI
controller (bus 3) at USB 2.0 speeds only. No typec/ucsi negotiation messages
appear - the driver fails silently.

**References:**
- Red Hat Bugzilla #2248484: UCSI driver bug
- Arch Linux Forum: https://bbs.archlinux.org/viewtopic.php?id=308325
- Kernel Bugzilla: https://bugzilla.kernel.org/show_bug.cgi?id=220904

**UCSI Driver Testing (2025-12-30):**

Tested whether UCSI driver is the root cause per kernel maintainer request.

| Test | UCSI Status | Boot with Dock | Hot-Plug | Result |
|------|-------------|----------------|----------|--------|
| Test 1 | Enabled (normal) | USB 3.0 works | FAILS | Only USB 2.0 enumerates |
| Test 2 | Disabled (blacklisted) | USB 3.0 works | FAILS | Same failure pattern |

**Conclusion:** Disabling UCSI does NOT resolve the issue. The problem is in the USB-C/Thunderbolt physical layer negotiation, not the UCSI driver.

Key log pattern on hot-plug (both tests):
```
usb usb1: root hub lost power or was reset
usb usb2: root hub lost power or was reset
usb 3-3: new high-speed USB device number 14 using xhci_hcd  ← USB 2.0 only
```

Test logs: `hardware/logs/bug-220904-test*.txt`

**Tested Workarounds That DON'T Work:**
- xHCI controller unbind/rebind (`echo 0000:00:0d.0 > unbind/bind`)
- UCSI driver reload (`modprobe -r ucsi_acpi && modprobe ucsi_acpi`)
- These don't work because the USB-C physical lane state is already established

**Working Workaround:** Boot with dock connected - ethernet works reliably.

**Alternative Workarounds:**
1. Plug dock in AFTER login screen appears (reported to work reliably)
2. Suspend/resume sometimes triggers re-enumeration
3. Disconnect and reconnect the USB-C cable multiple times
4. Use USB 2.0 ethernet adapter as fallback

```bash
# Quick diagnostic: Check if USB 3.0 is working
lsusb -t | grep "20000M"  # Should show devices under Bus 002

# Check typec port bindings (port0 should have usb3-port1 at boot)
ls -la /sys/class/typec/port*/usb*-port* 2>/dev/null

# Check which port dock is on
ls /sys/class/typec/ | grep partner  # port0-partner = good, port1-partner = USB 2.0 only

# Check if SuperSpeed lanes were negotiated
dmesg | grep -i "superspeed"
```

**Known Issue: Ethernet After Suspend/Resume**

The r8152 USB ethernet may fail to work after system suspend/resume. This is a known issue with S0 idle suspend on Intel platforms with USB docks.

**Symptoms after resume:**
- USB device detected (`lsusb` shows 17ef:a387)
- Driver loaded (`lsmod | grep r8152`)
- But driver doesn't attach to device
- No network interface appears or interface has no connectivity

**Attempted fixes that don't work:**
- Sleep hooks to reload driver (runs before USB re-enumerates)
- Systemd services after suspend.target (same timing issue)
- Manual `modprobe -r r8152 && modprobe r8152` (device not ready)

**Workaround:** Reboot the system.

```bash
# Check if ethernet is working
ip link show enp0s13f0u3u1
nmcli device status

# If not working after resume, reboot
systemctl reboot
```

**Verify USB autosuspend is disabled:**
```bash
cat /sys/bus/usb/devices/2-3.1/power/control  # Should show "on"
```

### Thunderbolt Docks

Thunderbolt 4 docks should work out of the box.

```bash
# Check Thunderbolt devices
boltctl list

# Authorize device (if needed)
boltctl authorize <uuid>
```

### USB Power

```bash
# Check USB device power
lsusb -v | grep -E "Bus|MaxPower"

# TLP USB settings
sudo tlp-stat -u
```

## External Storage

### USB Drives

Automatically mounted via udisks2.

```bash
# List drives
udisksctl status

# Mount
udisksctl mount -b /dev/sdb1

# Unmount
udisksctl unmount -b /dev/sdb1

# Safely remove
udisksctl power-off -b /dev/sdb
```

### Check Filesystem

```bash
# Before mounting
sudo fsck /dev/sdb1
```

## Webcam

### Built-in Camera

```bash
# Check device
v4l2-ctl --list-devices

# Test camera
mpv av://v4l2:/dev/video0
```

### Privacy Shutter

Physical privacy shutter on the webcam.

### Disable Camera

```bash
# Via kernel module
echo "blacklist uvcvideo" | sudo tee /etc/modprobe.d/no-webcam.conf
```

## External Monitors

See [04-DISPLAY-GRAPHICS](./04-DISPLAY-GRAPHICS.md) for external display configuration.

## Quick Reference

```bash
# Logitech
systemctl status logid
sudo systemctl restart logid
journalctl -u logid

# Yubikey
ykman info
ykman list

# USB devices
lsusb
lsusb -v

# Thunderbolt
boltctl list

# USB storage
udisksctl status
udisksctl mount -b /dev/sdb1
```

## Related

- [../systemd/08-HARDWARE.md](../systemd/08-HARDWARE.md) - logid service
- [04-DISPLAY-GRAPHICS](./04-DISPLAY-GRAPHICS.md) - External displays
- [06-NETWORKING-HW](./06-NETWORKING-HW.md) - Bluetooth devices
- [09-FIRMWARE](./09-FIRMWARE.md) - Dock firmware updates and BIOS update log
