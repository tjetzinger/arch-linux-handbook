# Android Apps (Waydroid)

Running Android applications on Arch Linux using Waydroid container technology.

## Overview

Waydroid uses Linux namespaces (LXC/LXD) to run a full Android system in a container. It provides native performance with GPU acceleration through Mesa, making it ideal for running Android apps on Wayland-based desktops like Hyprland.

| Component | Value |
|-----------|-------|
| **Solution** | Waydroid |
| **Android Version** | LineageOS 20 (Android 13) |
| **GPU Acceleration** | Mesa (Intel Iris Xe) |
| **Google Services** | GAPPS included |
| **Display Protocol** | Wayland native |

---

## Installation

### Prerequisites

```bash
# Required kernel support (check availability)
zgrep CONFIG_ANDROID /proc/config.gz
# CONFIG_ANDROID=y
# CONFIG_ANDROID_BINDER_IPC=y  # Required
# CONFIG_ANDROID_BINDERFS=y    # Required
```

### Install Waydroid

```bash
# Install from official repos
sudo pacman -S waydroid

# Enable the container service
sudo systemctl enable --now waydroid-container.service
```

### Initialize with Google Apps

```bash
# Initialize with GAPPS (Google Play Store)
sudo waydroid init -s GAPPS -f

# This downloads:
# - System image (~1.2GB): LineageOS with GAPPS
# - Vendor image (~180MB): Hardware abstraction layer
```

---

## Configuration

### GPU Acceleration

Waydroid automatically configures GPU acceleration. Current configuration:

```bash
# Check GPU settings
waydroid prop get ro.hardware.egl        # mesa
waydroid prop get ro.hardware.vulkan     # intel
waydroid prop get gralloc.gbm.device     # /dev/dri/renderD128
```

Configuration is stored in `/var/lib/waydroid/waydroid_base.prop`:

| Property | Value |
|----------|-------|
| `ro.hardware.gralloc` | gbm |
| `ro.hardware.egl` | mesa |
| `ro.hardware.vulkan` | intel |
| `gralloc.gbm.device` | /dev/dri/renderD128 |

### Google Play Store Certification

To use Google Play Store, register the device:

1. Get the Android ID:
```bash
sudo waydroid shell -- settings get secure android_id
```

2. Visit: https://www.google.com/android/uncertified/

3. Log in with your Google account

4. Enter the Android ID from step 1

5. Wait up to 24 hours for certification (usually faster)

6. Restart Waydroid:
```bash
waydroid session stop
waydroid session start
```

### Hyprland Window Rules

Window rules are configured in `~/.config/hypr/conf/custom.conf`:

```bash
# Waydroid window rules
windowrulev2 = float, class:^(Waydroid)$
windowrulev2 = size 480 800, class:^(Waydroid)$
windowrulev2 = center, class:^(Waydroid)$
windowrulev2 = idleinhibit focus, class:^(Waydroid)$
# For specific Android apps
windowrulev2 = float, title:^(Waydroid)$
windowrulev2 = idleinhibit focus, title:^(Waydroid)$
```

---

## Usage

### Session Management

```bash
# Start a session
waydroid session start

# Check status
waydroid status

# Stop session
waydroid session stop

# Restart container service
sudo systemctl restart waydroid-container.service
```

### Launching Android

```bash
# Full Android UI (home screen)
waydroid show-full-ui

# Launch specific app
waydroid app launch <package_name>

# List installed apps
waydroid app list
```

### Installing Apps

```bash
# Install APK file
waydroid app install /path/to/app.apk

# Install from Google Play Store (if certified)
# Use the Play Store app in the Android UI
```

### Android Shell Access

```bash
# Open Android shell
sudo waydroid shell

# Run specific command
sudo waydroid shell -- <command>

# Examples:
sudo waydroid shell -- pm list packages
sudo waydroid shell -- settings get secure android_id
```

---

## Advanced Configuration

### Custom Properties

Edit properties in `/var/lib/waydroid/waydroid.cfg`:

```ini
[waydroid]
# Shared folder (accessible from Android as /sdcard/Download/host)
mount_data = /home/tt/Downloads
```

### Network Configuration

Waydroid creates a NAT network:

| Setting | Value |
|---------|-------|
| **Interface** | waydroid0 |
| **IP Range** | 192.168.240.0/24 |
| **Host IP** | 192.168.240.1 |
| **DHCP Range** | 192.168.240.2-254 |

```bash
# Check network
ip addr show waydroid0
waydroid status  # Shows IP address
```

### UFW Firewall Configuration

If using UFW, configure NAT and forwarding rules:

**1. Add NAT masquerade to `/etc/ufw/before.rules`** (append after final COMMIT):

```bash
# NAT table rules for Waydroid
*nat
:POSTROUTING ACCEPT [0:0]
# Masquerade Waydroid traffic to internet (use your main interface)
-A POSTROUTING -s 192.168.240.0/24 -o wlan0 -j MASQUERADE
COMMIT
```

**2. Add UFW rules:**

```bash
# Allow DNS and DHCP on waydroid0 only
sudo ufw allow in on waydroid0 to any port 53
sudo ufw allow in on waydroid0 to any port 67

# Allow forwarding from waydroid0 to internet
sudo ufw route allow in on waydroid0 out on wlan0

# Reload firewall
sudo ufw reload
```

**3. Verify:**

```bash
sudo ufw status verbose
# Should show:
# 53 on waydroid0            ALLOW IN    Anywhere
# 67 on waydroid0            ALLOW IN    Anywhere
# Anywhere on wlan0          ALLOW FWD   Anywhere on waydroid0
```

**Note:** Replace `wlan0` with your actual internet interface (check with `ip route | grep default`).

### Performance Tuning

```bash
# For better touch/input performance
waydroid prop set persist.waydroid.udev true

# Disable cursor (if using touch-only apps)
waydroid prop set persist.waydroid.cursor_on_subsurface true
```

---

## Troubleshooting

### Session Won't Start

```bash
# Check container status
sudo systemctl status waydroid-container.service

# View logs
sudo waydroid log

# Reinitialize if needed
sudo waydroid init -f
```

### GPU Acceleration Issues

```bash
# Verify DRI device permissions
ls -la /dev/dri/

# Check if renderD128 is accessible
cat /var/lib/waydroid/waydroid_base.prop | grep gralloc

# Force software rendering (fallback)
waydroid prop set ro.hardware.egl swiftshader
```

### Google Play Not Working

1. Verify device registration at https://www.google.com/android/uncertified/
2. Clear Play Store cache in Android settings
3. Restart Waydroid session

```bash
waydroid session stop
waydroid session start
```

### App Crashes

```bash
# Check Android logs
sudo waydroid shell -- logcat

# Check if app requires specific architecture
# Waydroid is x86_64, some apps are ARM-only
```

### No Internet Connection

**Symptoms:** `IP address: UNKNOWN` or ping fails with "Network is unreachable"

**1. Check if Android has an IP:**
```bash
waydroid status
sudo waydroid shell -- ip addr show
```

**2. Restart session to trigger DHCP:**
```bash
waydroid session stop
waydroid session start
```

**3. Verify UFW rules (if using UFW):**
```bash
sudo ufw status verbose
# Must show rules for waydroid0 and routing
```

**4. Check NAT rules:**
```bash
sudo iptables -t nat -L POSTROUTING -v
# Should show MASQUERADE for 192.168.240.0/24
```

**5. Test connectivity:**
```bash
sudo waydroid shell -- ping -c 3 8.8.8.8
sudo waydroid shell -- ping -c 3 google.com
```

---

## Data Locations

| Item | Path |
|------|------|
| **Configuration** | `/var/lib/waydroid/waydroid.cfg` |
| **Base Properties** | `/var/lib/waydroid/waydroid_base.prop` |
| **System Image** | `/var/lib/waydroid/images/system.img` |
| **Vendor Image** | `/var/lib/waydroid/images/vendor.img` |
| **User Data** | `/var/lib/waydroid/data/` |
| **Container Logs** | `/var/lib/waydroid/lxc/` |

---

## Useful Commands

| Command | Description |
|---------|-------------|
| `waydroid status` | Show session and container status |
| `waydroid session start` | Start Android session |
| `waydroid session stop` | Stop Android session |
| `waydroid show-full-ui` | Launch full Android interface |
| `waydroid app list` | List installed Android apps |
| `waydroid app install <apk>` | Install APK file |
| `waydroid app launch <pkg>` | Launch app by package name |
| `sudo waydroid shell` | Open Android shell |
| `waydroid prop get <key>` | Get Android property |
| `waydroid prop set <key> <value>` | Set Android property |
| `sudo waydroid log` | View Waydroid logs |
| `sudo waydroid upgrade` | Check for OTA updates |

---

## Optional Enhancements

### 1. ARM Translation Layer (libhoudini)

For ARM-only Android apps, install the translation layer:

```bash
# Clone waydroid_script
git clone https://github.com/casualsnek/waydroid_script.git
cd waydroid_script

# Install dependencies
pip install -r requirements.txt

# Install libhoudini (ARM translation)
sudo python3 main.py install libhoudini

# Restart Waydroid
waydroid session stop
waydroid session start
```

**File:** Installed to `/var/lib/waydroid/overlay/`

---

### 2. Shared Folders

Share directories between host and Android:

**File:** `/var/lib/waydroid/waydroid.cfg`

```ini
[waydroid]
# Add this line to share Downloads folder
mount_data = /home/tt/Downloads
```

Access in Android: `/sdcard/Download/host/`

```bash
# Apply changes
waydroid session stop
waydroid session start
```

---

### 3. Rofi/Wofi Launcher Entry

Create a desktop entry for Waydroid:

**File:** `~/.local/share/applications/waydroid.desktop`

```ini
[Desktop Entry]
Name=Android (Waydroid)
Comment=Run Android apps via Waydroid
Exec=waydroid show-full-ui
Icon=waydroid
Terminal=false
Type=Application
Categories=System;Emulator;
Keywords=android;waydroid;apps;
```

```bash
# Update desktop database
update-desktop-database ~/.local/share/applications/
```

---

### 4. Hyprland Keyboard Shortcuts

Add keybindings for quick Android access:

**File:** `~/.config/hypr/conf/keybindings/custom.conf`

```bash
# Add to Actions section (around line 64)
bind = $mainMod, A, exec, waydroid show-full-ui                    # Launch Android UI
bind = $mainMod SHIFT, A, exec, waydroid session stop              # Stop Android session
```

```bash
# Reload config
hyprctl reload
```

---

### 5. Essential Android Apps

Recommended apps to install:

| App | Source | Notes |
|-----|--------|-------|
| F-Droid | https://f-droid.org | Open source app store |
| Aurora Store | F-Droid | Google Play alternative |
| Termux | F-Droid | Linux terminal emulator |
| K-9 Mail | F-Droid | Email client |
| Signal | APK/Play Store | Secure messaging |

```bash
# Install APK
waydroid app install ~/Downloads/app.apk

# List installed apps
waydroid app list
```

---

## Backup and Restore

### Backup Android Data

```bash
# Backup user data
sudo tar -czvf waydroid-backup.tar.gz /var/lib/waydroid/data/
```

### Restore

```bash
# Stop Waydroid
waydroid session stop
sudo systemctl stop waydroid-container.service

# Restore data
sudo tar -xzvf waydroid-backup.tar.gz -C /

# Restart
sudo systemctl start waydroid-container.service
waydroid session start
```

### Factory Reset

```bash
# Complete reset
waydroid session stop
sudo rm -rf /var/lib/waydroid/data
sudo waydroid init -f
```
