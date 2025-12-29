# Manual Recovery with Arch-Live Boot

This guide covers manual system recovery using the arch-live boot entry when the main system is unbootable.

## Prerequisites

- `arch-live` boot entry configured in systemd-boot
- LUKS encryption password (or keyfile access)
- Knowledge of your snapshot numbers (`snapper list`)

## System Layout Reference

| Component | Value |
|-----------|-------|
| Encrypted partition | `/dev/nvme0n1p2` |
| LUKS name | `cryptroot` |
| Btrfs UUID | `7baf5627-b3c5-4add-8b0e-fdd3488f00e0` |
| Root subvolume | `@arch` |
| Snapshots subvolume | `@.snapshots` |

---

## Step 1: Boot into Arch-Live

1. Reboot the system
2. At systemd-boot menu, select **Arch Linux Live**
3. Wait for the live environment to load

---

## Step 2: Unlock LUKS and Mount Btrfs

```bash
# Unlock the encrypted partition
cryptsetup open /dev/nvme0n1p2 cryptroot

# Mount the TOP-LEVEL btrfs volume (subvolid=5)
mount -o subvolid=5 /dev/mapper/cryptroot /mnt
```

### Verify the mount
```bash
ls /mnt
# Expected: @arch  @.snapshots  @Documents  @vm  @arch-live
```

---

## Step 3: Identify Available Snapshots

```bash
# List snapshot directories
ls /mnt/@.snapshots/

# Each numbered directory contains:
# - info.xml (metadata)
# - snapshot/ (the actual btrfs snapshot subvolume)

# View snapshot info
cat /mnt/@.snapshots/1575/info.xml
```

---

## Recovery Methods

### Method A: Full Subvolume Replacement (Complete Rollback)

This replaces your entire root with a snapshot.

```bash
# 1. Rename the broken root subvolume
mv /mnt/@arch /mnt/@arch-broken-$(date +%Y%m%d)

# 2. Create a new writable snapshot from the good snapshot
btrfs subvolume snapshot /mnt/@.snapshots/SNAPSHOT_NUMBER/snapshot /mnt/@arch

# 3. Verify
ls /mnt/@arch

# 4. Cleanup and reboot
umount /mnt
cryptsetup close cryptroot
reboot
```

**Example with snapshot 1575:**
```bash
mv /mnt/@arch /mnt/@arch-broken-20251213
btrfs subvolume snapshot /mnt/@.snapshots/1575/snapshot /mnt/@arch
umount /mnt
reboot
```

---

### Method B: Selective File Restoration

Restore specific files/directories from a snapshot without full rollback.

```bash
# 1. Mount the snapshot separately
mkdir -p /mnt/snapshot
mount -o subvol=@.snapshots/SNAPSHOT_NUMBER/snapshot,ro /dev/mapper/cryptroot /mnt/snapshot

# 2. Mount current root
mkdir -p /mnt/current
mount -o subvol=@arch /dev/mapper/cryptroot /mnt/current

# 3. Compare and copy specific files
diff /mnt/snapshot/etc/pacman.conf /mnt/current/etc/pacman.conf
cp -a /mnt/snapshot/etc/specific-config /mnt/current/etc/

# 4. For entire directories
rsync -av /mnt/snapshot/etc/systemd/ /mnt/current/etc/systemd/

# 5. Cleanup
umount /mnt/snapshot /mnt/current
```

---

### Method C: Use Snapper from Live Environment

Run snapper commands targeting the mounted system.

```bash
# 1. Mount root and snapshots properly
mount -o subvol=@arch /dev/mapper/cryptroot /mnt
mount -o subvol=@.snapshots /dev/mapper/cryptroot /mnt/.snapshots

# 2. List snapshots via snapper
snapper --root /mnt list

# 3. View changes between snapshots
snapper --root /mnt status SNAPSHOT1..SNAPSHOT2

# 4. Undo changes between two snapshots
snapper --root /mnt undochange SNAPSHOT1..SNAPSHOT2

# 5. Cleanup
umount /mnt/.snapshots
umount /mnt
```

---

## Post-Recovery Tasks

After successful recovery and reboot:

```bash
# 1. Verify system is working
systemctl --failed

# 2. Check what was restored
snapper list

# 3. Create a new snapshot of the recovered state
sudo snapper create -d "After recovery - stable state" --type single

# 4. (Optional) Delete broken subvolume to reclaim space
sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt
sudo btrfs subvolume delete /mnt/@arch-broken-20251213
sudo umount /mnt
```

---

## Troubleshooting

### Cannot unlock LUKS
```bash
# Try with verbose output
cryptsetup open /dev/nvme0n1p2 cryptroot --debug

# Check if already open
ls /dev/mapper/
```

### Snapshot directory is empty
```bash
# Verify btrfs mount
btrfs subvolume list /mnt

# Check if snapshots exist
btrfs subvolume list /mnt | grep snapshots
```

### Permission denied errors
```bash
# Ensure you're running as root in live environment
sudo -i
```

### After rollback, packages are outdated
```bash
# Normal - you rolled back to an older state
# Update carefully
sudo pacman -Syu
```

---

## Quick Reference Card

```
# UNLOCK
cryptsetup open /dev/nvme0n1p2 cryptroot

# MOUNT TOP-LEVEL
mount -o subvolid=5 /dev/mapper/cryptroot /mnt

# ROLLBACK
mv /mnt/@arch /mnt/@arch-broken
btrfs subvolume snapshot /mnt/@.snapshots/NUMBER/snapshot /mnt/@arch

# CLEANUP & REBOOT
umount /mnt && reboot
```
