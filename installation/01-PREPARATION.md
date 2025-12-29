# 01 - Preparation

Pre-installation checklist and environment setup.

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | x86_64 with UEFI | Intel/AMD with AES-NI |
| RAM | 2 GB | 8+ GB |
| Storage | 20 GB | 256+ GB NVMe |
| Network | Ethernet or WiFi | |

### Verify Hardware Support

```bash
# Check UEFI mode
ls /sys/firmware/efi/efivars  # Should list variables

# Check CPU supports AES-NI (for fast encryption)
grep -o aes /proc/cpuinfo | head -1  # Should output "aes"

# Check NVMe disk
lsblk  # Should show nvme0n1 or similar
```

---

## Create Installation Media

### Download Arch ISO

```bash
# On existing Linux system
cd ~/Downloads

# Download latest ISO
curl -LO https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
curl -LO https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso.sig

# Verify signature
gpg --keyserver-options auto-key-retrieve --verify archlinux-x86_64.iso.sig
```

### Write to USB

```bash
# Identify USB device (BE CAREFUL - wrong device = data loss)
lsblk

# Write ISO (replace sdX with your USB device)
sudo dd bs=4M if=archlinux-x86_64.iso of=/dev/sdX status=progress oflag=sync
```

---

## BIOS/UEFI Configuration

Enter BIOS setup (usually F1, F2, F12, Del, or Esc during boot).

### Required Settings

| Setting | Value | Notes |
|---------|-------|-------|
| Boot Mode | UEFI only | Disable Legacy/CSM |
| Secure Boot | Disabled | Enable later if desired |
| SATA Mode | AHCI | Not RAID or IDE |

### Recommended Settings

| Setting | Value | Notes |
|---------|-------|-------|
| TPM | Enabled | For future TPM unlock |
| Virtualization | Enabled | VT-x/AMD-V for VMs |
| Thunderbolt Security | User Authorization | If applicable |

---

## Boot from USB

1. Insert USB drive
2. Boot and enter boot menu (F12 on most systems)
3. Select USB drive (UEFI mode)
4. Select "Arch Linux install medium"

---

## Initial Live Environment Setup

### Set Keyboard Layout

```bash
# List available layouts
localectl list-keymaps | grep -i de

# Load German layout (adjust for your keyboard)
loadkeys de-latin1

# Or US layout
loadkeys us
```

### Connect to Internet

#### Wired (Ethernet)
```bash
# Usually works automatically
ping -c 3 archlinux.org
```

#### WiFi
```bash
# Interactive WiFi setup
iwctl

# Inside iwctl:
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "YourSSID"
# Enter password when prompted
exit

# Verify connection
ping -c 3 archlinux.org
```

#### Alternative WiFi (one-liner)
```bash
iwctl --passphrase="YourPassword" station wlan0 connect "YourSSID"
```

### Verify Boot Mode

```bash
# Must show files for UEFI mode
ls /sys/firmware/efi/efivars
```

### Update System Clock

```bash
timedatectl set-ntp true
timedatectl status
```

### Update Mirror List (Optional)

```bash
# Install reflector
pacman -Sy reflector

# Get fastest mirrors
reflector --country Germany,Austria,Switzerland \
          --protocol https \
          --age 12 \
          --sort rate \
          --save /etc/pacman.d/mirrorlist
```

---

## Identify Target Disk

```bash
# List all disks
lsblk

# Detailed disk info
fdisk -l

# Identify your target disk (e.g., /dev/nvme0n1)
# WARNING: All data on this disk will be destroyed!
```

### Common Disk Names

| Type | Device Path |
|------|-------------|
| NVMe SSD | `/dev/nvme0n1` |
| SATA SSD/HDD | `/dev/sda` |
| Virtual disk | `/dev/vda` |

---

## Pre-Installation Checklist

Before proceeding to disk setup:

- [ ] Booted in UEFI mode (efivars accessible)
- [ ] Connected to internet (ping works)
- [ ] Correct keyboard layout loaded
- [ ] Target disk identified
- [ ] **All important data backed up** (disk will be wiped!)
- [ ] Installation variables prepared (hostname, username, passwords)

---

## Variables to Prepare

Have these ready before starting:

| Variable | Example | Your Value |
|----------|---------|------------|
| Hostname | `x1carbon` | |
| Username | `tt` | |
| User password | (strong) | |
| Root password | (strong) | |
| LUKS password | (very strong, memorable) | |
| Timezone | `Europe/Berlin` | |
| Locale | `en_US.UTF-8` | |
| Keymap | `de-latin1` | |
| WiFi SSID | `MyNetwork` | |
| WiFi password | | |

---

## Next Step

Proceed to [02-DISK-SETUP.md](./02-DISK-SETUP.md) for disk partitioning and encryption.
