# LUKS Key Management

Guide for managing LUKS encryption keys and headers on this system.

## Current Configuration

| Property | Value |
|----------|-------|
| Device | `/dev/nvme0n1p2` |
| LUKS Version | 2 |
| UUID | `dd8c7166-cbef-454c-a046-9a7efc26bb60` |
| Cipher | `aes-xts-plain64` |
| Key Size | 512 bits |
| PBKDF | argon2id |
| Keyslots Used | 0, 1 |
| Total Keyslots | 32 (LUKS2 max) |

---

## Understanding Keyslots

LUKS2 supports up to 32 keyslots. Each keyslot can hold a different password or keyfile that unlocks the same master encryption key.

```bash
# View current keyslot status
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep -A2 "Keyslots:"
```

Your system uses:
- **Keyslot 0**: Password (interactive)
- **Keyslot 1**: Keyfile (automatic boot unlock)

---

## Critical: Backup LUKS Header First

**Always backup the header before making any changes!**

```bash
# Create header backup
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 \
    --header-backup-file /safe/location/luks-header-$(date +%Y%m%d).bin

# Verify backup size (should be ~16MB for LUKS2)
ls -lh /safe/location/luks-header-*.bin
```

### Store Header Backup Safely
- External USB drive (encrypted)
- Password manager (as attachment)
- Separate cloud storage (encrypted)
- Safety deposit box

**Why it matters:** If all keyslots are corrupted or you forget all passwords, the header backup + one working password = data recovery.

---

## Key Management Operations

### Add a New Password

```bash
# Add password to next available keyslot
sudo cryptsetup luksAddKey /dev/nvme0n1p2

# Add to specific keyslot (e.g., slot 2)
sudo cryptsetup luksAddKey /dev/nvme0n1p2 --key-slot 2

# You'll be prompted for:
# 1. Existing password (to authorize)
# 2. New password (to add)
```

### Add a Keyfile

```bash
# Generate random keyfile
dd if=/dev/urandom of=/root/backup-keyfile bs=4096 count=1
chmod 400 /root/backup-keyfile

# Add keyfile to LUKS
sudo cryptsetup luksAddKey /dev/nvme0n1p2 /root/backup-keyfile

# Store keyfile securely (separate from encrypted drive!)
```

### Remove a Password/Key

```bash
# Remove by providing the password to remove
sudo cryptsetup luksRemoveKey /dev/nvme0n1p2
# Enter the password you want to remove

# Remove specific keyslot
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 <slot-number>
# Enter a remaining valid password to authorize
```

### Change a Password

```bash
# Change password in existing slot
sudo cryptsetup luksChangeKey /dev/nvme0n1p2

# You'll enter:
# 1. Current password
# 2. New password
```

---

## Keyfile for Automatic Boot (Current Setup)

Your system uses a keyfile for automatic unlocking at boot:

```
rd.luks.key=dd8c7166-cbef-454c-a046-9a7efc26bb60=/luks-keyfile.bin:UUID=c55a9bf0-7a6b-4299-ab21-1e3af3d36657
```

This means:
- Keyfile: `/luks-keyfile.bin`
- Located on: Partition with UUID `c55a9bf0-7a6b-4299-ab21-1e3af3d36657` (likely boot/ESP)
- Timeout: 5 seconds (`keyfile-timeout=5s`), then falls back to password

### Regenerate Boot Keyfile

```bash
# Generate new keyfile
sudo dd if=/dev/urandom of=/boot/luks-keyfile.bin bs=4096 count=1
sudo chmod 400 /boot/luks-keyfile.bin

# Add to LUKS (keep old one until verified!)
sudo cryptsetup luksAddKey /dev/nvme0n1p2 /boot/luks-keyfile.bin

# Test boot works, then remove old keyfile's slot if needed
```

---

## Header Restore (Emergency)

If LUKS header is corrupted:

```bash
# Boot from live USB
# DO NOT try to open the device first

# Restore header from backup
sudo cryptsetup luksHeaderRestore /dev/nvme0n1p2 \
    --header-backup-file /path/to/luks-header-backup.bin

# Now try to open
sudo cryptsetup open /dev/nvme0n1p2 cryptroot
```

---

## Security Best Practices

### Do
- Keep header backup in multiple secure locations
- Use strong, unique passwords (20+ chars or passphrase)
- Keep at least 2 keyslots active (password + recovery)
- Test recovery procedures periodically

### Don't
- Store keyfile on same drive as encrypted data
- Use same password for LUKS and user account
- Delete all keyslots (you'll lose access!)
- Share header backup with encryption password

---

## Verify Keyslot Status

```bash
# Quick check of used slots
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep "Keyslot"

# Detailed view
sudo cryptsetup luksDump /dev/nvme0n1p2
```

---

## Emergency Recovery Scenarios

### Forgot Password, Have Keyfile
```bash
# Open with keyfile
sudo cryptsetup open /dev/nvme0n1p2 cryptroot --key-file /path/to/keyfile

# Add new password
sudo cryptsetup luksAddKey /dev/nvme0n1p2 --key-file /path/to/keyfile
```

### Forgot Password, Have Header Backup
```bash
# If you have header backup + remember OLD password
sudo cryptsetup luksHeaderRestore /dev/nvme0n1p2 \
    --header-backup-file /backup/luks-header.bin
# Then open with old password
```

### All Keys Lost, No Header Backup
**Data is unrecoverable.** This is by design - encryption works.

---

## USB Unlock Key

Create a USB stick that can automatically unlock the system at boot, with password as fallback.

### Overview

| Component | Description |
|-----------|-------------|
| USB keyfile | Random 4KB file stored on USB |
| LUKS slot | New keyslot (e.g., slot 2) for USB key |
| Boot entry | Checks USB first, falls back to password |
| Timeout | Configurable wait time for USB |

### Step 1: Prepare USB Stick

```bash
# Identify USB device (BE CAREFUL - wrong device = data loss!)
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT

# Example: USB is /dev/sda
USB_DEV=/dev/sda

# Create partition table and filesystem
sudo parted $USB_DEV --script mklabel gpt
sudo parted $USB_DEV --script mkpart primary fat32 1MiB 100%
sudo mkfs.fat -F32 -n CRYPTKEY ${USB_DEV}1

# Get UUID of new partition
USB_UUID=$(lsblk -no UUID ${USB_DEV}1)
echo "USB UUID: $USB_UUID"
```

### Step 2: Create Keyfile on USB

```bash
# Mount USB
sudo mkdir -p /mnt/usb
sudo mount ${USB_DEV}1 /mnt/usb

# Generate random keyfile (4KB)
sudo dd if=/dev/urandom of=/mnt/usb/luks-key.bin bs=4096 count=1
sudo chmod 400 /mnt/usb/luks-key.bin

# Verify
ls -la /mnt/usb/luks-key.bin
```

### Step 3: Add Keyfile to LUKS

```bash
# Backup LUKS header first!
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 \
    --header-backup-file ~/luks-header-backup-$(date +%Y%m%d).bin

# Add USB keyfile to LUKS (slot 2)
sudo cryptsetup luksAddKey /dev/nvme0n1p2 /mnt/usb/luks-key.bin --key-slot 2
# Enter existing password when prompted

# Verify new keyslot
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep -A1 "2: luks2"

# Test keyfile works
sudo cryptsetup open --test-passphrase /dev/nvme0n1p2 --key-file /mnt/usb/luks-key.bin
echo "Keyfile valid!" || echo "Keyfile FAILED!"

# Unmount USB
sudo umount /mnt/usb
```

### Step 4: Create Boot Entry for USB Unlock

Create a new boot entry that checks USB first:

```bash
# Get USB partition UUID
USB_UUID="<your-usb-uuid-here>"

# Create boot entry
sudo tee /boot/loader/entries/arch-usbkey.conf << EOF
title   Arch Linux (USB Key)
linux   /EFI/arch/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot root=/dev/mapper/cryptroot rd.luks.key=dd8c7166-cbef-454c-a046-9a7efc26bb60=/luks-key.bin:UUID=${USB_UUID} rd.luks.options=dd8c7166-cbef-454c-a046-9a7efc26bb60=keyfile-timeout=10s rootflags=subvol=@arch rw
EOF
```

**Boot options explained:**
- `rd.luks.key=...:/luks-key.bin:UUID=<usb-uuid>` - Look for keyfile on USB
- `keyfile-timeout=10s` - Wait 10 seconds for USB, then prompt for password

### Step 5: Configure Boot Loader

```bash
# Edit loader.conf to set default or show menu
sudo nano /boot/loader/loader.conf
```

```ini
default arch.conf
timeout 5
console-mode max
editor no
```

Options:
- Keep `arch.conf` as default (password unlock)
- Change to `arch-usbkey.conf` (USB unlock default)
- Set `timeout 5` to choose at boot

### Step 6: Test the Setup

1. **Reboot with USB plugged in**
   - Select "Arch Linux (USB Key)" from boot menu
   - System should unlock automatically

2. **Reboot without USB**
   - Select "Arch Linux (USB Key)"
   - After 10s timeout, password prompt appears
   - Or select regular "Arch Linux" entry

3. **Verify both methods work before relying on them!**

### Alternative: Single Boot Entry with USB Fallback

Instead of separate entries, modify main entry to check USB then boot partition:

```bash
# Boot checks USB first, then boot partition keyfile, then password
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot \
    root=/dev/mapper/cryptroot \
    rd.luks.key=dd8c7166-cbef-454c-a046-9a7efc26bb60=/luks-key.bin:UUID=<USB_UUID> \
    rd.luks.key=dd8c7166-cbef-454c-a046-9a7efc26bb60=/luks-keyfile.bin:UUID=c55a9bf0-7a6b-4299-ab21-1e3af3d36657 \
    rd.luks.options=dd8c7166-cbef-454c-a046-9a7efc26bb60=keyfile-timeout=5s \
    rootflags=subvol=@arch rw
```

### Security Considerations

| Risk | Mitigation |
|------|------------|
| USB lost/stolen | USB alone can't boot without the drive |
| USB keyfile copied | Use encrypted USB or hardware security key |
| Multiple unlock methods | Audit keyslots regularly |
| USB damaged | Keep password method working as backup |

### Maintenance

```bash
# List all keyslots
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep -E "^  [0-9]:"

# Remove USB keyslot if compromised
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 2

# Regenerate USB keyfile
sudo dd if=/dev/urandom of=/mnt/usb/luks-key.bin bs=4096 count=1
sudo cryptsetup luksAddKey /dev/nvme0n1p2 /mnt/usb/luks-key.bin --key-slot 2
```

### Quick Setup Script

```bash
#!/bin/bash
# create-usb-unlock-key.sh
# Run with: sudo ./create-usb-unlock-key.sh /dev/sdX

set -e
USB_DEV="$1"

if [[ -z "$USB_DEV" ]]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

echo "WARNING: This will ERASE $USB_DEV"
read -p "Continue? (yes/no): " confirm
[[ "$confirm" != "yes" ]] && exit 1

# Format USB
parted "$USB_DEV" --script mklabel gpt
parted "$USB_DEV" --script mkpart primary fat32 1MiB 100%
mkfs.fat -F32 -n CRYPTKEY "${USB_DEV}1"

# Create keyfile
mkdir -p /mnt/usb
mount "${USB_DEV}1" /mnt/usb
dd if=/dev/urandom of=/mnt/usb/luks-key.bin bs=4096 count=1
chmod 400 /mnt/usb/luks-key.bin

# Add to LUKS
echo "Enter existing LUKS password to add USB key:"
cryptsetup luksAddKey /dev/nvme0n1p2 /mnt/usb/luks-key.bin --key-slot 2

# Get UUID
USB_UUID=$(lsblk -no UUID "${USB_DEV}1")
echo ""
echo "USB Key created successfully!"
echo "USB UUID: $USB_UUID"
echo ""
echo "Add this boot entry to /boot/loader/entries/arch-usbkey.conf"

umount /mnt/usb
```

---

## Quick Reference

```bash
# View header info
sudo cryptsetup luksDump /dev/nvme0n1p2

# Backup header
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file backup.bin

# Add password
sudo cryptsetup luksAddKey /dev/nvme0n1p2

# Remove password
sudo cryptsetup luksRemoveKey /dev/nvme0n1p2

# Change password
sudo cryptsetup luksChangeKey /dev/nvme0n1p2

# Test password without mounting
sudo cryptsetup open --test-passphrase /dev/nvme0n1p2
```
