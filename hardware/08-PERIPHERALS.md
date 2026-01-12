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
```

**Fix 2: udev rule** - Restart logid when Logitech device connects

This handles the bluez 5.77+ timing issue where devices timeout during initial connection.

**File:** `/etc/udev/rules.d/99-logitech-logid-restart.rules`
```udev
# Restart logid when Logitech Bluetooth HID devices connect
# Fixes bluez 5.77+ timing issue where logid fails to configure device
# Bluetooth devices use uhid with format 0005:VENDOR:PRODUCT
ACTION=="add", SUBSYSTEM=="hidraw", KERNELS=="0005:046D:*", \
  RUN+="/bin/bash -c 'sleep 2 && systemctl restart logid.service &'"
```

**Note:** Bluetooth HID devices don't have `ATTRS{idVendor}` - the vendor ID is embedded in `KERNELS` as `0005:046D:*` (0005 = Bluetooth bus type).

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
          { direction: "None"; mode: "OnRelease";  // Tap: Overview
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_A"]; }; },
          { direction: "Up"; mode: "OnRelease";    // Swipe up: Workspace down
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_PAGEDOWN"]; }; },
          { direction: "Down"; mode: "OnRelease";  // Swipe down: Workspace up
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_PAGEUP"]; }; },
          { direction: "Left"; mode: "OnRelease";  // Swipe left: Focus column right
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_RIGHT"]; }; },
          { direction: "Right"; mode: "OnRelease"; // Swipe right: Focus column left
            action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_LEFT"]; }; }
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

### MX Master 3S Gesture Button (Niri)

| Gesture | Action | Keybinding |
|---------|--------|------------|
| Tap | Overview | Mod+A |
| Swipe Left | Focus column right | Mod+Right |
| Swipe Right | Focus column left | Mod+Left |
| Swipe Up | Workspace down | Mod+Page_Down |
| Swipe Down | Workspace up | Mod+Page_Up |

**Note:** Gestures use natural direction (content moves with swipe).

### Volume Step Configuration

The MX Master 3S thumbwheel sends `XF86AudioRaiseVolume`/`XF86AudioLowerVolume` keys. Volume step is configured in Hyprland keybindings.

**Problem:** ML4W's `default.conf` binds volume keys at 5% step. Adding bindings in `custom.conf` causes both to fire (6% total).

**Solution:** Use `unbind` to remove defaults, then `bindle` for 1% step with hold-to-repeat.

**File:** `~/.config/hypr/conf/keybindings/custom.conf`

```bash
# Volume keys - unbind defaults (5%) and rebind with 1% step
unbind = , XF86AudioRaiseVolume
unbind = , XF86AudioLowerVolume
bindle = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+  # 1% step
bindle = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-       # 1% step
```

| Binding | Behavior |
|---------|----------|
| `bind` | Single keypress only |
| `bindle` | Fires on hold/repeat (smooth scrolling) |

This approach survives ML4W migrations since `custom.conf` is preserved.

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

**RESOLVED: USB 3.0 Hot-Plug Issue**

**Kernel Bug:** https://bugzilla.kernel.org/show_bug.cgi?id=220904

**Symptom:** Dock's USB 3.0 devices (ethernet, USB 3.0 ports) did not enumerate on hot-plug. Only USB 2.0 devices worked.

**Root Cause (2025-12-31):** xHCI runtime power management was set to `auto`, causing the controller to not properly handle hot-plug events.

**Fix:** Remove `xhci_hcd` from TLP's `RUNTIME_PM_DRIVER_DENYLIST` so TLP sets xHCI to `on` on AC power.

```bash
# Add to /etc/tlp.conf:
RUNTIME_PM_DRIVER_DENYLIST="mei_me nouveau radeon"  # removed xhci_hcd
```

**Note:** TLP ships with `xhci_hcd` in the default denylist (`defaults.conf`), which leaves xHCI at kernel default (`auto`). This prevents TLP from managing the xHCI controller.

**Verify fix is applied:**
```bash
# Check xHCI runtime PM (should be "on" on AC)
cat /sys/bus/pci/devices/0000:00:0d.0/power/control

# Check TLP effective settings
sudo tlp-stat -e | grep "0d.0"
```

<details>
<summary><strong>Investigation History (2025-12-24 to 2025-12-31)</strong></summary>

**Initial symptoms on hot-plug:**
- `lsusb` shows only USB 2.0 dock devices (17ef:a392, 17ef:a396, 17ef:a38f)
- USB 3.0 devices missing (17ef:a391, 17ef:a387)
- Ethernet interface does not appear

**Investigation steps:**
- BIOS updated from 1.22 → 1.38
- Dock firmware at 5.05.00 (latest)
- UCSI driver testing - disabling did NOT fix issue
- Thunderbolt debug logging (`thunderbolt.dyndbg=+p`) - showed ethernet never re-registered
- xHCI runtime PM testing - **this was the root cause**

**Key discovery:** TLP's default denylist includes `xhci_hcd`, preventing TLP from setting xHCI to `on`. The kernel default is `auto`, which causes hot-plug failures.

**References:**
- Kernel Bugzilla: https://bugzilla.kernel.org/show_bug.cgi?id=220904
- Arch Linux Forum: https://bbs.archlinux.org/viewtopic.php?id=308325

</details>

**Known Issue: USB 3.0 Devices Lost After Suspend/Resume (Kernel 6.16+ Regression)**

The dock's USB 3.0 devices (including ethernet) fail to reconnect after s2idle suspend/resume. This is a **kernel regression introduced in 6.16** affecting xHCI suspend/resume on Intel systems.

**Symptoms after resume:**
- USB 2.0 dock devices work (audio, USB 2.0 hub)
- USB 3.0 devices missing (`lsusb` doesn't show 17ef:a387 or 17ef:a391)
- No ethernet interface appears
- dmesg shows: `r8152-cfgselector 2-3.1: USB disconnect`

**Root cause:** Kernel 6.16+ introduced a regression in xHCI resume handling. The USB 3.0 SuperSpeed link fails to re-enumerate after s2idle resume.

| Issue | Status |
|-------|--------|
| Bug #219824 (xHCI "HC died") | **FIXED** in 6.13.7 |
| Bug #220904 (hot-plug) | **FIXED** via TLP denylist |
| 6.16+ xHCI resume regression | **UNFIXED** - tracking in Fedora #2393013 |

**Related kernel 6.16+ issues** (all connected to the same regression):

| Symptom | Affected Systems |
|---------|------------------|
| USB input dead after wake | USB-C docks (this case) |
| Kernel panic on wake | Intel systems with `intel_oc_wdt` |
| System reboots during suspend | Dell XPS, laptops with Intel WiFi |
| NVMe lost after resume | Some NVMe + s2idle combinations |

**S3 deep sleep not available:** This system only supports s2idle (Modern Standby). S3 suspend-to-RAM is not an option.

**Attempted fixes that don't work (tested 2025-12-31):**
- xHCI controller unbind/rebind
- UCSI connector reset
- Thunderbolt NHI reset
- PCI rescan / USB bus rescan
- Thunderbolt module reload
- `xhci_hcd.quirks=0x80` (RESET_ON_RESUME) - already enabled

**Workaround:** Unplug and replug the USB-C cable after resume.

```bash
# Check if USB 3.0 devices are present
lsusb | grep "17ef:a387"  # Ethernet
lsusb | grep "17ef:a391"  # USB 3.0 hub

# If missing after resume, physically replug the USB-C cable
```

**Tracking:**
- Kernel Bugzilla #220904: https://bugzilla.kernel.org/show_bug.cgi?id=220904
- Fedora Bug #2393013 (6.16 regression): https://bugzilla.redhat.com/show_bug.cgi?id=2393013
- Arch Forums: https://bbs.archlinux.org/viewtopic.php?id=307641

**Potential workarounds to test when fixes land:**
- Kernel 6.19+ may include fix (monitor changelogs)
- Downgrade to 6.15-zen if available (not practical for custom kernel)

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
