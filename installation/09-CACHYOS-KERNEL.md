# 09 - CachyOS Kernel Setup

Install and configure the CachyOS kernel alongside the standard Arch kernel with proper EFI boot support.

## Overview

The CachyOS kernel is a performance-optimized kernel with BORE scheduler and additional patches. When using a custom EFI directory structure (kernels in `/boot/EFI/arch/` instead of `/boot/`), additional configuration is required.

---

## Problem: Boot Failure After Kernel Upgrade

### Symptoms

```
mount: /boot: unknown filesystem type 'vfat'
```

After upgrading `linux-cachyos`, the system fails to boot with vfat module errors.

### Root Cause

Two issues combine to cause this failure:

#### 1. Preset Path Mismatch

The default CachyOS mkinitcpio preset writes to `/boot/`:

```bash
# Default (broken for custom EFI setup)
ALL_kver="/boot/vmlinuz-linux-cachyos"
default_image="/boot/initramfs-linux-cachyos.img"
```

But systemd-boot entries reference `/boot/EFI/arch/`:

```conf
linux /EFI/arch/vmlinuz-linux-cachyos
initrd /EFI/arch/initramfs-linux-cachyos.img
```

#### 2. Pacman Hook Timing (if using copy hook)

Pacman hooks sort **alphabetically**, not numerically:

```
"100-" runs BEFORE "90-" because "1" < "9"
```

A hook named `100-linux-cachyos.hook` runs **before** `90-mkinitcpio-install.hook`, attempting to copy files that don't exist yet.

### Timeline of Failure

```
1. Kernel package upgraded
2. Copy hook runs (file doesn't exist yet) → FAILS
3. mkinitcpio runs, creates /boot/vmlinuz-linux-cachyos
4. Boot entry points to /boot/EFI/arch/ (old version)
5. Old kernel tries to load modules from deleted version
6. vfat.ko not found → /boot mount fails
```

---

## Solution: Configure Preset for EFI Path

### Step 1: Edit the Preset

```bash
sudo vim /etc/mkinitcpio.d/linux-cachyos.preset
```

Change paths to write directly to EFI directory:

```bash
# mkinitcpio preset file for the 'linux-cachyos' package

ALL_kver="/boot/EFI/arch/vmlinuz-linux-cachyos"

PRESETS=('default')

default_image="/boot/EFI/arch/initramfs-linux-cachyos.img"
```

### Step 2: Remove Any Copy Hook (if exists)

```bash
# Check for copy hook
ls /etc/pacman.d/hooks/*cachyos*

# Remove if exists (no longer needed)
sudo rm /etc/pacman.d/hooks/*linux-cachyos*.hook
```

### Step 3: Copy Current Kernel and Regenerate

```bash
# Copy kernel to EFI location
sudo cp /boot/vmlinuz-linux-cachyos /boot/EFI/arch/

# Regenerate initramfs at new location
sudo mkinitcpio -p linux-cachyos
```

### Step 4: Clean Up Orphan Files

```bash
# Remove old files from /boot/ (now in /boot/EFI/arch/)
sudo rm /boot/vmlinuz-linux-cachyos /boot/initramfs-linux-cachyos.img
```

### Step 5: Verify

```bash
# Check kernel version
strings /boot/EFI/arch/vmlinuz-linux-cachyos | grep -E "^6\.[0-9]+"

# Verify boot entry
cat /boot/loader/entries/linux-cachyos.conf
```

---

## systemd-boot Entry

Create or verify `/boot/loader/entries/linux-cachyos.conf`:

```conf
title CachyOS Linux
linux /EFI/arch/vmlinuz-linux-cachyos
initrd /intel-ucode.img
initrd /EFI/arch/initramfs-linux-cachyos.img
options rd.luks.name=<UUID>=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@arch rw quiet splash
```

---

## Comparison: Arch vs CachyOS Kernel Setup

| Aspect | linux (Arch) | linux-cachyos |
|--------|--------------|---------------|
| Preset path | `/boot/EFI/arch/vmlinuz-linux` | Must be changed to `/boot/EFI/arch/` |
| Copy hook needed | No | No (after fix) |
| Updates | Automatic | Automatic (after fix) |

---

## Installing CachyOS Kernel (Fresh Install)

### Step 1: Add CachyOS Repository

```bash
# Import keys
sudo pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key F3B607488DB35A47

# Add repository to /etc/pacman.conf
[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
```

### Step 2: Install Kernel

```bash
sudo pacman -S linux-cachyos linux-cachyos-headers
```

### Step 3: Configure Preset (IMPORTANT)

**Before first boot**, edit the preset:

```bash
sudo vim /etc/mkinitcpio.d/linux-cachyos.preset
```

Set EFI paths:

```bash
ALL_kver="/boot/EFI/arch/vmlinuz-linux-cachyos"
default_image="/boot/EFI/arch/initramfs-linux-cachyos.img"
```

### Step 4: Regenerate Initramfs

```bash
sudo mkinitcpio -p linux-cachyos
```

### Step 5: Create Boot Entry

```bash
sudo vim /boot/loader/entries/linux-cachyos.conf
```

---

## Troubleshooting

### Check Kernel Version Mismatch

```bash
# Installed package version
pacman -Q linux-cachyos

# Kernel in EFI
strings /boot/EFI/arch/vmlinuz-linux-cachyos | grep -E "^6\.[0-9]+-.*cachyos"

# Available modules
ls /lib/modules/ | grep cachyos
```

All three should show the **same version**.

### Recovery from Boot Failure

1. Boot from USB or working kernel (Arch)
2. Mount and chroot:
   ```bash
   cryptsetup open /dev/nvme0n1p2 cryptroot
   mount -o subvol=@arch /dev/mapper/cryptroot /mnt
   mount /dev/nvme0n1p1 /mnt/boot
   arch-chroot /mnt
   ```
3. Fix preset and regenerate:
   ```bash
   vim /etc/mkinitcpio.d/linux-cachyos.preset
   cp /boot/vmlinuz-linux-cachyos /boot/EFI/arch/
   mkinitcpio -p linux-cachyos
   ```

### Verify Hook Order (if using hooks)

```bash
# List all hooks
ls /etc/pacman.d/hooks/ /usr/share/libalpm/hooks/ | sort

# Hooks sort ALPHABETICALLY:
# 05-* < 100-* < 30-* < 90-*
# (because "1" < "3" < "9")
```

---

## Quick Reference

| File | Purpose |
|------|---------|
| `/etc/mkinitcpio.d/linux-cachyos.preset` | Kernel/initramfs paths |
| `/boot/EFI/arch/vmlinuz-linux-cachyos` | Kernel image |
| `/boot/EFI/arch/initramfs-linux-cachyos.img` | Initramfs |
| `/boot/loader/entries/linux-cachyos.conf` | Boot entry |
| `/lib/modules/<version>/` | Kernel modules |

---

## Related Documentation

- [04-BOOTLOADER.md](04-BOOTLOADER.md) - Base bootloader setup
- [../system-recovery/](../system-recovery/) - Recovery procedures
