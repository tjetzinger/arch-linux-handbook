# 06 - Networking Hardware

WiFi 6E and Bluetooth hardware configuration.

## WiFi

### Hardware

**Intel AX211 (WiFi 6E)**

```bash
lspci | grep Network
```

```
Intel Corporation Raptor Lake PCH CNVi WiFi (rev 01)
```

### Specifications

| Feature | Value |
|---------|-------|
| Standard | WiFi 6E (802.11ax) |
| Bands | 2.4 GHz, 5 GHz, 6 GHz |
| Max Speed | 2.4 Gbps |
| MU-MIMO | Yes |
| OFDMA | Yes |
| WPA3 | Yes |

### Driver

```bash
lsmod | grep iwlwifi
```

| Module | Purpose |
|--------|---------|
| iwlwifi | Intel WiFi driver |
| iwlmvm | Intel MAC layer |

### Firmware

```bash
dmesg | grep iwlwifi | head -5
```

Firmware files in `/lib/firmware/`.

### Configuration

**File:** `/etc/modprobe.d/iwlwifi.conf` (if needed)

```bash
# Disable power saving (if connection issues)
options iwlwifi power_save=0

# Enable 802.11n/ac
options iwlwifi 11n_disable=0
```

### Commands

```bash
# Connection status
nmcli device wifi

# List available networks
nmcli device wifi list

# Connect to network
nmcli device wifi connect "SSID" password "password"

# Show connection details
nmcli connection show "SSID"

# WiFi power
nmcli radio wifi on
nmcli radio wifi off
```

### Power Saving

TLP manages WiFi power saving:

```bash
# In /etc/tlp.conf
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
```

### Check Signal Strength

```bash
# Current connection
iwctl station wlan0 show

# Or via nmcli
nmcli -f IN-USE,SIGNAL,SSID device wifi list
```

### 6 GHz Band

WiFi 6E adds the 6 GHz band:

```bash
# Check if 6 GHz is available
iw phy | grep -A 20 "6 GHz"

# Regulatory domain
iw reg get
```

**Note:** 6 GHz availability depends on country regulations.

### Regulatory Domain

The WiFi regulatory domain controls which frequencies, channels, and power levels are allowed based on country laws.

#### Check Current Setting

```bash
iw reg get
# Look for "country XX:" line
```

#### Set Temporarily

```bash
sudo iw reg set DE
```

#### Set Persistently

Two methods ensure the regulatory domain persists across reboots:

**Method 1:** Kernel module option

**File:** `/etc/modprobe.d/wifi-regdom.conf`
```bash
options cfg80211 ieee80211_regdom=DE
```

**Method 2:** wireless-regdb config

**File:** `/etc/conf.d/wireless-regdom`
```bash
WIRELESS_REGDOM="DE"
```

#### Setup Commands

```bash
# Install regulatory database
sudo pacman -S wireless-regdb

# Create persistent config
echo 'options cfg80211 ieee80211_regdom=DE' | sudo tee /etc/modprobe.d/wifi-regdom.conf

# Enable in wireless-regdom config
sudo sed -i 's/^#WIRELESS_REGDOM="DE"/WIRELESS_REGDOM="DE"/' /etc/conf.d/wireless-regdom

# Apply immediately (without reboot)
sudo iw reg set DE
```

#### Verify

```bash
iw reg get | grep country
# Should show: country DE
```

| Country | Code |
|---------|------|
| Germany | DE |
| Austria | AT |
| Switzerland | CH |
| USA | US |
| UK | GB |

## Bluetooth

### Hardware

**Intel AX211 Bluetooth (integrated with WiFi)**

```bash
lsusb | grep Intel
```

```
Intel Corp. AX211 Bluetooth
```

### Specifications

| Feature | Value |
|---------|-------|
| Version | Bluetooth 5.3 |
| Profiles | A2DP, HSP, HFP, HID |
| Codecs | SBC, AAC, aptX, LDAC |

### Driver

```bash
lsmod | grep btusb
```

### Service

```bash
systemctl status bluetooth
```

### Boot Race Condition Fix

The bluetooth.service may fail to start at boot due to a race condition - systemd checks for `/sys/class/bluetooth` before the kernel creates it.

**Symptom:**
```
Bluetooth service was skipped because of an unmet condition check (ConditionPathIsDirectory=/sys/class/bluetooth).
```

**Fix:** Systemd override to wait for the hci0 device instead of checking the directory.

**File:** `/etc/systemd/system/bluetooth.service.d/wait-for-device.conf`
```ini
[Unit]
# Clear the condition that causes boot race condition
ConditionPathIsDirectory=
# Wait for Bluetooth device to be ready
After=sys-subsystem-bluetooth-devices-hci0.device
Wants=sys-subsystem-bluetooth-devices-hci0.device
```

**Apply:**
```bash
sudo systemctl daemon-reload
```

**Verify after reboot:**
```bash
systemctl status bluetooth.service
```

### bluetoothctl

Main command-line tool for Bluetooth.

```bash
bluetoothctl

# In bluetoothctl:
power on
agent on
default-agent
scan on
pair <MAC>
connect <MAC>
trust <MAC>
disconnect <MAC>
remove <MAC>
```

### Common Commands

```bash
# Show adapter info
bluetoothctl show

# List paired devices
bluetoothctl devices

# Connect to device
bluetoothctl connect XX:XX:XX:XX:XX:XX

# Power control
bluetoothctl power on
bluetoothctl power off
```

### Auto-Connect

Trust devices to auto-connect:

```bash
bluetoothctl trust XX:XX:XX:XX:XX:XX
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

### Power Saving

```bash
# TLP keeps Bluetooth from autosuspend
# In /etc/tlp.conf
USB_EXCLUDE_BTUSB=1
```

### Connected Devices

Current connected Bluetooth devices:
- MX Master 3S (Bluetooth mouse)
- MX Keys Mini (Bluetooth keyboard)

See [08-PERIPHERALS](./08-PERIPHERALS.md) for logid configuration.

## Airplane Mode

### Toggle via rfkill

```bash
# Check status
rfkill list

# Block all wireless
rfkill block all

# Unblock all wireless
rfkill unblock all

# Block specific
rfkill block bluetooth
rfkill block wifi
```

### Via NetworkManager

```bash
# Airplane mode
nmcli radio all off
nmcli radio all on
```

### Fn Key

**Fn+F8** toggles airplane mode via thinkpad_acpi.

## Troubleshooting

### WiFi Not Connecting

```bash
# Check device state
nmcli device status

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check driver messages
dmesg | grep iwlwifi

# Reset wireless
sudo modprobe -r iwlmvm iwlwifi
sudo modprobe iwlwifi
```

### WiFi Slow/Unstable

```bash
# Disable power saving
sudo iw dev wlan0 set power_save off

# Or permanently in /etc/modprobe.d/iwlwifi.conf
options iwlwifi power_save=0

# Check for interference
nmcli device wifi list | sort -k6 -nr | head
```

### Bluetooth Won't Pair

```bash
# Restart Bluetooth
sudo systemctl restart bluetooth

# Remove and re-pair
bluetoothctl remove XX:XX:XX:XX:XX:XX
bluetoothctl scan on
bluetoothctl pair XX:XX:XX:XX:XX:XX

# Check logs
journalctl -u bluetooth
```

### Bluetooth Audio Issues

```bash
# Check PipeWire Bluetooth
systemctl --user status pipewire

# Reconnect device
bluetoothctl disconnect XX:XX:XX:XX:XX:XX
bluetoothctl connect XX:XX:XX:XX:XX:XX

# Set audio profile
pactl set-card-profile bluez_card.XX_XX_XX_XX_XX_XX a2dp-sink
```

## Network Manager Integration

```bash
# Show all connections
nmcli connection show

# Edit connection
nmcli connection edit "Connection Name"

# WiFi settings
nmcli connection modify "SSID" wifi.powersave 2  # Disable power save
```

## Quick Reference

```bash
# WiFi
nmcli device wifi list
nmcli device wifi connect "SSID" password "pass"
nmcli radio wifi on/off

# Bluetooth
bluetoothctl
bluetoothctl power on
bluetoothctl connect XX:XX:XX:XX:XX:XX

# Airplane mode
rfkill list
rfkill block/unblock all

# Driver info
lsmod | grep iwlwifi
dmesg | grep iwlwifi
```

## Related

- [../networking/](../networking/) - Tailscale and DNS
- [05-AUDIO](./05-AUDIO.md) - Bluetooth audio
- [08-PERIPHERALS](./08-PERIPHERALS.md) - Bluetooth devices
