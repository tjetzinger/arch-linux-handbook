# Boot Partition Backup

The EFI System Partition (ESP) / boot partition is **not covered by Btrfs snapshots**. This guide covers backing up and restoring `/boot`.

## Why Boot Needs Separate Backup

| Component | Location | Snapshotted? |
|-----------|----------|--------------|
| Root filesystem | Btrfs @ subvolume | Yes (snapper) |
| Boot partition | `/boot` (FAT32) | **No** |

The boot partition contains:
- Kernel images (`vmlinuz-linux`)
- Initramfs (`initramfs-linux.img`)
- Microcode (`intel-ucode.img`, `amd-ucode.img`)
- Bootloader (`systemd-boot`, EFI files)
- Boot entries (`loader/entries/*.conf`)
- LUKS keyfile (if used)

---

## Current Boot Partition Contents

```
/boot
├── EFI/
│   ├── arch/           # Arch kernel & initramfs
│   ├── arch-live/      # Live system kernel
│   ├── arch-lts/       # LTS kernel
│   ├── BOOT/           # Fallback bootloader
│   ├── Linux/          # Linux EFI stub
│   └── systemd/        # systemd-boot EFI
├── loader/
│   ├── loader.conf     # Boot configuration
│   └── entries/        # Boot menu entries
├── intel-ucode.img     # CPU microcode
└── luks-keyfile.bin    # LUKS unlock key (if present)
```

---

## Backup Methods

### Method 1: Simple Tar Archive

```bash
#!/bin/bash
# /usr/local/bin/backup-boot

BACKUP_DIR="~/Documents/boot-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/boot-${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"

# Create backup
sudo tar -czf "$BACKUP_FILE" -C / boot

# Keep only last 5 backups
ls -t "${BACKUP_DIR}"/boot-*.tar.gz | tail -n +6 | xargs -r rm

echo "Boot partition backed up to: $BACKUP_FILE"
ls -lh "$BACKUP_FILE"
```

### Method 2: Rsync Mirror

```bash
#!/bin/bash
# /usr/local/bin/backup-boot-rsync

BACKUP_DIR="~/Documents/boot-mirror"
mkdir -p "$BACKUP_DIR"

sudo rsync -av --delete /boot/ "$BACKUP_DIR/"

echo "Boot partition mirrored to: $BACKUP_DIR"
```

### Method 3: Include in Borg Backup

Already included if you backup `/boot` in your Borg script (recommended).

```bash
# In borg-backup script, ensure /boot is included:
BACKUP_PATHS=(
    "/boot"    # <-- Add this
    "/etc"
    "/home"
    ...
)
```

---

## Automated Boot Backup on Kernel Update

### Pacman Hook

Create hook to backup boot before kernel updates:

```bash
sudo tee /etc/pacman.d/hooks/50-boot-backup.hook << 'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = linux
Target = linux-lts
Target = linux-zen
Target = systemd
Target = intel-ucode
Target = amd-ucode

[Action]
Description = Backing up /boot...
When = PreTransaction
Exec = /usr/local/bin/backup-boot
AbortOnFail
EOF
```

### Create Backup Script

```bash
sudo tee /usr/local/bin/backup-boot << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="~/Documents/boot-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/boot-${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_FILE" -C / boot

# Keep last 10 backups
ls -t "${BACKUP_DIR}"/boot-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm

logger "Boot partition backed up to $BACKUP_FILE"
EOF

sudo chmod +x /usr/local/bin/backup-boot
```

---

## Restore Boot Partition

### Scenario 1: Restore Files on Working System

```bash
# From tar backup
BACKUP="~/Documents/boot-backups/boot-20241213_120000.tar.gz"
sudo tar -xzf "$BACKUP" -C /

# From rsync mirror
sudo rsync -av ~/Documents/boot-mirror/ /boot/

# Reinstall bootloader to be safe
sudo bootctl update
```

### Scenario 2: Restore from Arch Live

```bash
# 1. Mount partitions
cryptsetup open /dev/nvme0n1p2 cryptroot
mount -o subvol=@arch /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot

# 2. Access backup (example: from encrypted home)
mount -o subvol=@Documents /dev/mapper/cryptroot /mnt~/Documents

# 3. Restore boot
tar -xzf /mnt~/Documents/boot-backups/boot-*.tar.gz -C /mnt/

# 4. Reinstall bootloader
arch-chroot /mnt
bootctl install
exit

# 5. Unmount and reboot
umount -R /mnt
reboot
```

### Scenario 3: Restore from Borg

```bash
# From arch-live
mkdir /borg
mount /dev/sdX1 /borg  # External drive

export BORG_PASSPHRASE="passphrase"
cd /mnt
borg extract /borg/borg-backup::latest boot/

# Reinstall bootloader
arch-chroot /mnt bootctl install
```

---

## Complete Boot Disaster Recovery

If boot partition is completely corrupted or disk replaced:

```bash
# 1. Boot from Arch ISO

# 2. Partition and format new EFI partition
mkfs.fat -F32 /dev/nvme0n1p1

# 3. Mount everything
cryptsetup open /dev/nvme0n1p2 cryptroot
mount -o subvol=@arch /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot

# 4. Restore from backup
# Either extract tar, or rsync from mirror, or borg extract

# 5. Chroot and reinstall bootloader
arch-chroot /mnt
bootctl install

# 6. Regenerate initramfs
mkinitcpio -P

# 7. Verify boot entries
ls /boot/loader/entries/
cat /boot/loader/entries/arch.conf

# 8. Update if LUKS UUID changed
blkid /dev/nvme0n1p2  # Get new UUID
# Edit boot entries with new UUID if needed

# 9. Exit and reboot
exit
umount -R /mnt
reboot
```

---

## Boot Entry Backup

Backup just the boot configurations (lightweight):

```bash
#!/bin/bash
# Backup boot loader configuration

BACKUP_DIR="$HOME/Documents/boot-configs"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"

cp /boot/loader/loader.conf "$BACKUP_DIR/loader.conf.$DATE"
cp -r /boot/loader/entries "$BACKUP_DIR/entries-$DATE"

echo "Boot configs saved to $BACKUP_DIR"
```

---

## Verify Boot Partition Health

```bash
# Check filesystem
sudo fsck.fat -n /dev/nvme0n1p1

# Check space usage
df -h /boot

# Verify bootloader
bootctl status

# List boot entries
bootctl list
```

---

## LUKS Keyfile Considerations

If you use a LUKS keyfile on the boot partition:

1. **Backup the keyfile separately** (it's critical)
2. **Keep it in your Borg backup**
3. **Consider having password as backup keyslot**

```bash
# Backup keyfile specifically
sudo cp /boot/luks-keyfile.bin /safe/encrypted/location/

# Verify you have password keyslot working
sudo cryptsetup open --test-passphrase /dev/nvme0n1p2
```

---

## Recommended Backup Schedule

| What | When | Method |
|------|------|--------|
| Full /boot | Before kernel updates | Pacman hook |
| Full /boot | Weekly | Include in Borg |
| Boot configs only | After changes | Manual script |
| LUKS keyfile | After creation | Manual to safe location |

---

## Quick Reference

```bash
# Backup boot (manual)
sudo tar -czf ~/boot-backup.tar.gz -C / boot

# Restore boot
sudo tar -xzf ~/boot-backup.tar.gz -C /

# Reinstall systemd-boot
sudo bootctl install

# Regenerate initramfs
sudo mkinitcpio -P

# Check boot status
bootctl status
bootctl list
```
