# 06 - Snapper Setup

Configure automatic Btrfs snapshots with Snapper.

## Prerequisites

- System booted and working
- Btrfs filesystem with `@.snapshots` subvolume
- `/.snapshots` mount point exists

---

## Step 1: Install Snapper and Tools

```bash
sudo pacman -S snapper snap-pac grub-btrfs inotify-tools
```

| Package | Purpose |
|---------|---------|
| `snapper` | Snapshot manager |
| `snap-pac` | Pacman hook for pre/post snapshots |
| `grub-btrfs` | Boot menu snapshot entries (optional) |
| `inotify-tools` | File watching (for grub-btrfs) |

**Note:** Even with systemd-boot, grub-btrfs can be useful for snapshot browsing.

---

## Step 2: Create Snapper Config

### Unmount Existing .snapshots (Important!)

Snapper wants to create its own subvolume, but we already have `@.snapshots`.

```bash
# Unmount snapper directory
sudo umount /.snapshots

# Remove the directory snapper will create
sudo rmdir /.snapshots
```

### Create Snapper Configuration

```bash
sudo snapper -c root create-config /
```

### Fix Snapper's Subvolume

Snapper created its own `.snapshots` subvolume. Delete it and remount ours:

```bash
# Delete snapper's subvolume
sudo btrfs subvolume delete /.snapshots

# Recreate mount point
sudo mkdir /.snapshots

# Remount our @.snapshots subvolume
sudo mount -o subvol=@.snapshots /dev/mapper/cryptroot /.snapshots

# Verify
ls -la /.snapshots
mount | grep snapshots
```

### Set Permissions

```bash
sudo chmod 750 /.snapshots
sudo chown :wheel /.snapshots
```

---

## Step 3: Configure Snapper

### Edit Configuration

```bash
sudo vim /etc/snapper/configs/root
```

### Recommended Settings

```ini
# Allow users in wheel group to use snapper
ALLOW_GROUPS="wheel"

# Snapshot creation settings
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"

# Timeline limits (adjust to your preference)
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"

# Number limits for pre/post snapshots (from snap-pac)
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"

# Empty pre/post cleanup
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
```

---

## Step 4: Enable Snapper Services

```bash
# Timeline snapshots (hourly)
sudo systemctl enable snapper-timeline.timer
sudo systemctl start snapper-timeline.timer

# Cleanup old snapshots
sudo systemctl enable snapper-cleanup.timer
sudo systemctl start snapper-cleanup.timer
```

### Verify Timers

```bash
systemctl list-timers | grep snapper
```

---

## Step 5: Create Initial Snapshot

```bash
sudo snapper -c root create -d "Initial system snapshot"
```

### Verify

```bash
snapper list
ls /.snapshots/
```

---

## Step 6: Test snap-pac

snap-pac automatically creates pre/post snapshots on pacman operations.

```bash
# Install a test package
sudo pacman -S cowsay

# Check snapshots
snapper list | tail -5
# Should show pre and post entries for "pacman -S cowsay"

# Remove the package
sudo pacman -R cowsay

# Check again
snapper list | tail -5
```

---

## Step 7: Allow User Access (Optional)

Allow your regular user to use snapper without sudo for viewing:

```bash
# Already set ALLOW_GROUPS="wheel" in config

# Verify user is in wheel group
groups tt

# User can now run
snapper list
snapper diff 1..2
```

For operations that modify (create, delete, rollback), sudo is still required.

---

## Using Snapper

### List Snapshots

```bash
snapper list

# Show more details
snapper list -a
```

### Create Manual Snapshot

```bash
sudo snapper -c root create -d "Before risky change"
```

### Compare Snapshots

```bash
# List changed files
snapper status 1..2

# Show diff
snapper diff 1..2
snapper diff 1..2 /etc/pacman.conf
```

### Undo Changes

```bash
# Revert changes between two snapshots
sudo snapper undochange 1..2

# Revert specific files
sudo snapper undochange 1..2 /etc/pacman.conf
```

### Delete Snapshot

```bash
sudo snapper delete 5
sudo snapper delete 5-10
```

### Rollback (Full System)

```bash
sudo snapper rollback 5
# Then reboot
```

---

## Snapshot Boot Entries (Optional)

For systemd-boot, create a script to generate snapshot entries.

### Create Script

```bash
sudo tee /usr/local/bin/snapshot-boot-entry << 'EOF'
#!/bin/bash
# Generate systemd-boot entry for a snapper snapshot

SNAPSHOT_NUM="$1"
if [[ -z "$SNAPSHOT_NUM" ]]; then
    echo "Usage: snapshot-boot-entry <snapshot-number>"
    exit 1
fi

if [[ ! -d "/.snapshots/${SNAPSHOT_NUM}" ]]; then
    echo "Snapshot ${SNAPSHOT_NUM} not found"
    exit 1
fi

# Get LUKS UUID
LUKS_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)
EFI_UUID=$(blkid -s UUID -o value /dev/nvme0n1p1)

cat > "/boot/loader/entries/arch-snapshot-${SNAPSHOT_NUM}.conf" << ENTRY
title   Arch Linux (Snapshot $SNAPSHOT_NUM)
linux   /EFI/arch/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rd.luks.key=${LUKS_UUID}=/luks-keyfile.bin:UUID=${EFI_UUID} rd.luks.options=${LUKS_UUID}=keyfile-timeout=5s rootflags=subvol=@.snapshots/${SNAPSHOT_NUM}/snapshot rw
ENTRY

echo "Created: /boot/loader/entries/arch-snapshot-${SNAPSHOT_NUM}.conf"
EOF

sudo chmod +x /usr/local/bin/snapshot-boot-entry
```

### Usage

```bash
# Create entry for snapshot 5
sudo snapshot-boot-entry 5

# List entries
ls /boot/loader/entries/

# Remove when done
sudo rm /boot/loader/entries/arch-snapshot-5.conf
```

---

## Automatic Cleanup

Snapper automatically cleans old snapshots based on your configuration.

### Manual Cleanup

```bash
# Clean based on timeline rules
sudo snapper cleanup timeline

# Clean based on number rules
sudo snapper cleanup number
```

### Check Space Usage

```bash
# Btrfs usage
sudo btrfs filesystem usage /

# Snapshot sizes (approximate)
sudo btrfs filesystem du -s /.snapshots/*/snapshot | head -20
```

---

## Quick Reference

```bash
# Install
sudo pacman -S snapper snap-pac

# Create config (after unmounting /.snapshots)
sudo umount /.snapshots
sudo rmdir /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -o subvol=@.snapshots /dev/mapper/cryptroot /.snapshots

# Enable timers
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

# Common commands
snapper list
sudo snapper create -d "description"
snapper status 1..2
snapper diff 1..2
sudo snapper undochange 1..2
sudo snapper rollback 5
```

---

## Next Step

Proceed to [07-DESKTOP-HYPRLAND.md](./07-DESKTOP-HYPRLAND.md) for desktop environment setup.
