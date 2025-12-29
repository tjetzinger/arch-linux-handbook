# Snapper Systemd-Boot Integration

This guide covers setting up boot entries for Btrfs snapshots with systemd-boot, allowing you to boot directly into a snapshot from the boot menu.

## Overview

Unlike GRUB with grub-btrfs, systemd-boot doesn't automatically generate snapshot boot entries. This guide provides manual and automated methods to create them.

---

## Method 1: Manual Boot Entry Creation

### Create a Single Snapshot Boot Entry

```bash
# Template location
/boot/loader/entries/arch-snapshot-XXXX.conf
```

**Example: Create entry for snapshot 1575**

```bash
sudo tee /boot/loader/entries/arch-snapshot-1575.conf << 'EOF'
title   Arch Linux (Snapshot 1575: Before Plasma)
linux   /EFI/arch/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=<LUKS-UUID>=cryptroot root=/dev/mapper/cryptroot rd.luks.key=<LUKS-UUID>=/luks-keyfile.bin:UUID=<EFI-UUID> rd.luks.options=<LUKS-UUID>=keyfile-timeout=5s rootflags=subvol=@.snapshots/1575/snapshot rw
EOF
```

**Key difference from normal boot entry:**
```
rootflags=subvol=@.snapshots/1575/snapshot
```
Instead of:
```
rootflags=subvol=@arch
```

### Verify Entry
```bash
bootctl list
```

---

## Method 2: Automated Script

### Install the Generator Script

```bash
sudo tee /usr/local/bin/snapshot-boot-entry << 'EOF'
#!/bin/bash
# Generate systemd-boot entry for a snapper snapshot
# Usage: snapshot-boot-entry <snapshot-number> [description]

set -e

SNAPSHOT_NUM="$1"
CUSTOM_DESC="$2"

if [[ -z "$SNAPSHOT_NUM" ]]; then
    echo "Usage: snapshot-boot-entry <snapshot-number> [description]"
    echo "       snapshot-boot-entry --list"
    echo "       snapshot-boot-entry --clean"
    exit 1
fi

# List existing snapshot entries
if [[ "$SNAPSHOT_NUM" == "--list" ]]; then
    echo "Existing snapshot boot entries:"
    ls -la /boot/loader/entries/arch-snapshot-*.conf 2>/dev/null || echo "  None found"
    exit 0
fi

# Clean all snapshot entries
if [[ "$SNAPSHOT_NUM" == "--clean" ]]; then
    echo "Removing all snapshot boot entries..."
    rm -f /boot/loader/entries/arch-snapshot-*.conf
    echo "Done."
    exit 0
fi

# Verify snapshot exists
if [[ ! -d "/.snapshots/${SNAPSHOT_NUM}" ]]; then
    echo "Error: Snapshot ${SNAPSHOT_NUM} not found in /.snapshots/"
    exit 1
fi

# Get description from snapper if not provided
# Snapper output format: "  NUM │ Description"
if [[ -z "$CUSTOM_DESC" ]]; then
    CUSTOM_DESC=$(snapper list --columns number,description | awk -F '│' -v num="$SNAPSHOT_NUM" '$1 ~ num {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | head -1)
    [[ -z "$CUSTOM_DESC" ]] && CUSTOM_DESC="Snapshot ${SNAPSHOT_NUM}"
fi

# Get snapshot date
SNAP_DATE=$(snapper list --columns number,date | awk -F '│' -v num="$SNAPSHOT_NUM" '$1 ~ num {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | head -1)

ENTRY_FILE="/boot/loader/entries/arch-snapshot-${SNAPSHOT_NUM}.conf"

cat > "${ENTRY_FILE}" << ENTRY
title   Arch Linux (Snap ${SNAPSHOT_NUM}: ${CUSTOM_DESC})
linux   /EFI/arch/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=<LUKS-UUID>=cryptroot root=/dev/mapper/cryptroot rd.luks.key=<LUKS-UUID>=/luks-keyfile.bin:UUID=<EFI-UUID> rd.luks.options=<LUKS-UUID>=keyfile-timeout=5s rootflags=subvol=@.snapshots/${SNAPSHOT_NUM}/snapshot rw
ENTRY

echo "Created: ${ENTRY_FILE}"
echo "  Snapshot: ${SNAPSHOT_NUM}"
echo "  Description: ${CUSTOM_DESC}"
echo "  Date: ${SNAP_DATE}"
EOF

sudo chmod +x /usr/local/bin/snapshot-boot-entry
```

### Usage

```bash
# Create entry for specific snapshot
sudo snapshot-boot-entry 1575

# Create entry with custom description
sudo snapshot-boot-entry 1575 "Before Plasma Install"

# List existing snapshot entries
sudo snapshot-boot-entry --list

# Remove all snapshot entries
sudo snapshot-boot-entry --clean
```

---

## Method 3: Automatic Entry Generation (Systemd Service)

### Create Snapper Hook Script

```bash
sudo tee /usr/local/bin/snapper-boot-hook << 'EOF'
#!/bin/bash
# Automatically create boot entries for important snapshots
# Called by snapper post-hooks or manually

# Keep boot entries for:
# - Last 3 single (manual) snapshots
# - All pre snapshots from last 24 hours (for rollback)

KEEP_SINGLE=3
KEEP_HOURS=24

# Clean old entries
rm -f /boot/loader/entries/arch-snapshot-*.conf

# Get recent single snapshots (manual snapshots)
# Snapper output uses │ as delimiter
snapper list --columns number,type | awk -F '│' '/single/ {gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' | tail -${KEEP_SINGLE} | while read NUM; do
    /usr/local/bin/snapshot-boot-entry "$NUM" 2>/dev/null
done

# Get recent pre snapshots (for rollback after package changes)
CUTOFF=$(date -d "${KEEP_HOURS} hours ago" +%s)
snapper list --columns number,type,date | awk -F '│' '/pre/ {gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $3); print $1 "|" $3}' | while IFS='|' read NUM DATE; do
    SNAP_TIME=$(date -d "$DATE" +%s 2>/dev/null || echo 0)
    if [[ $SNAP_TIME -gt $CUTOFF ]]; then
        /usr/local/bin/snapshot-boot-entry "$NUM" 2>/dev/null
    fi
done

echo "Boot entries updated. Current entries:"
ls /boot/loader/entries/arch-snapshot-*.conf 2>/dev/null || echo "  None"
EOF

sudo chmod +x /usr/local/bin/snapper-boot-hook
```

### Create Systemd Service and Timer

```bash
# Service
sudo tee /etc/systemd/system/snapper-boot-entries.service << 'EOF'
[Unit]
Description=Generate systemd-boot entries for snapper snapshots
After=snapper-timeline.service snapper-cleanup.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/snapper-boot-hook
EOF

# Timer (runs hourly)
sudo tee /etc/systemd/system/snapper-boot-entries.timer << 'EOF'
[Unit]
Description=Update snapshot boot entries hourly

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable timer
sudo systemctl daemon-reload
sudo systemctl enable --now snapper-boot-entries.timer
```

---

## Booting into a Snapshot

### Important: Snapshots Boot Read-Only by Default

When you boot into a snapshot:

1. The system loads from the snapshot subvolume
2. **Changes cannot be persisted** without additional steps
3. Use this to **verify the snapshot works** before committing

### After Booting into Snapshot

**If the snapshot works and you want to keep it:**

```bash
# Option 1: Use snapper rollback (creates new snapshot, sets as default)
sudo snapper rollback

# Option 2: Manual - remount rw and make permanent (advanced)
# See Manual Recovery documentation
```

**If you just wanted to test:**

Simply reboot - system returns to normal `@arch` subvolume.

---

## Workflow Example: Installing Plasma

### Before Installation

```bash
# 1. Create a named snapshot
sudo snapper create -d "Before Plasma install" --type single
snapper list | tail -3
# Note the number, e.g., 1580

# 2. Create a boot entry for it
sudo snapshot-boot-entry 1580 "Pre-Plasma Clean System"

# 3. Verify
bootctl list | grep -i snap
```

### Install Plasma

```bash
sudo pacman -S plasma-meta
# snap-pac automatically creates pre/post snapshots
```

### If Plasma Breaks the System

**Option A: System still boots**
```bash
# Find pre-install snapshot
snapper list | grep -i plasma

# Undo changes
sudo snapper undochange 1580..1582
```

**Option B: System won't boot**

1. At boot menu, select `Arch Linux (Snap 1580: Pre-Plasma Clean System)`
2. Verify system works
3. Run `sudo snapper rollback` to make it permanent
4. Reboot

---

## Cleanup

Remove old snapshot boot entries:

```bash
# Remove specific entry
sudo rm /boot/loader/entries/arch-snapshot-1575.conf

# Remove all snapshot entries
sudo snapshot-boot-entry --clean

# Or manually
sudo rm /boot/loader/entries/arch-snapshot-*.conf
```

---

## Troubleshooting

### Snapshot boot hangs or fails

There are two common causes:

**Cause 1: fstab conflict**

The `/etc/fstab` inside the snapshot specifies `subvol=/@arch` for the root mount. When booting a snapshot, systemd reads this fstab and tries to remount `/` with the wrong subvolume.

**Solution:** Remove the `subvol=` option from the root entry in `/etc/fstab`:

```bash
# Before (causes snapshot boot to fail)
UUID=...  /  btrfs  rw,relatime,ssd,discard,space_cache=v2,subvol=/@arch  0 0

# After (allows snapshot booting)
UUID=...  /  btrfs  rw,relatime,ssd,discard,space_cache=v2  0 0
```

**Important:** Only remove `subvol=` from the `/` entry. Keep it for all other mounts.

**Cause 2: Read-only snapshot**

Snapper creates read-only snapshots by default. Systemd needs to write to `/var`, `/tmp`, etc. during boot.

**Solution:** Make the snapshot writable before booting:

```bash
# Check if read-only
sudo btrfs property get /.snapshots/1234/snapshot ro

# Make writable
sudo btrfs property set /.snapshots/1234/snapshot ro false
```

**Note:** The `snapshot-boot-entry` script automatically makes snapshots writable when creating boot entries.

### Boot entry doesn't appear in menu
```bash
# Verify file exists and has correct permissions
ls -la /boot/loader/entries/

# Check bootctl
bootctl list

# Verify loader.conf
cat /boot/loader/loader.conf
```

### Snapshot boots but filesystem is read-only
```bash
# This is expected! Snapshots are read-only
# Remount rw if needed (temporary)
sudo mount -o remount,rw /

# For permanent change, use snapper rollback
```

### Wrong kernel version in snapshot
If the snapshot was created before a kernel update, the current kernel in `/boot` might not match. Solutions:

1. Keep multiple kernel versions installed (`linux` and `linux-lts`)
2. Create separate boot entries with LTS kernel for snapshots
3. Use the matching initramfs from the snapshot (advanced)

---

## Alternative AUR Packages

| Package | Description |
|---------|-------------|
| `snapper-systemd-boot` (if available) | Automatic entry generation |
| `snap-pac` | Already installed - creates pre/post snapshots |
| `snapper-gui` | GUI for snapper management |

Check AUR:
```bash
yay -Ss snapper systemd-boot
```
