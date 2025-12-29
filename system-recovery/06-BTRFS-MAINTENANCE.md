# Btrfs Maintenance Guide

Regular maintenance tasks for the Btrfs filesystem.

## Current Layout

| Subvolume | Mount Point | Purpose |
|-----------|-------------|---------|
| `@arch` | `/` | Root filesystem |
| `@arch-live` | `/mnt/arch-live` | Live environment |
| `@Documents` | `~/Documents` | User documents |
| `@.snapshots` | `/.snapshots` | Snapper snapshots |
| `@vm` | `/mnt/vm` | Virtual machines |

**Device:** `/dev/mapper/cryptroot`
**UUID:** `<SWAP-UUID>`

---

## Regular Maintenance Tasks

### 1. Scrub (Data Integrity Check)

Scrub reads all data and metadata, verifying checksums and repairing corrupted blocks (if redundancy exists).

```bash
# Start scrub on root filesystem
sudo btrfs scrub start /

# Check scrub status
sudo btrfs scrub status /

# View last scrub results
sudo btrfs scrub status -d /
```

**Recommended frequency:** Monthly

#### Automated Scrub with Systemd Timer

```bash
# Arch provides btrfs-scrub@.timer
sudo systemctl enable btrfs-scrub@-.timer  # For root
sudo systemctl start btrfs-scrub@-.timer

# Check timer status
systemctl list-timers | grep scrub
```

---

### 2. Balance (Chunk Rebalancing)

Balance redistributes data across devices and reclaims unused space from deleted subvolumes.

```bash
# Light balance (metadata only, safe)
sudo btrfs balance start -musage=50 /

# Data balance (more aggressive, slower)
sudo btrfs balance start -dusage=50 /

# Full balance (slow, use sparingly)
sudo btrfs balance start /

# Check balance status
sudo btrfs balance status /

# Cancel running balance
sudo btrfs balance cancel /
```

**Recommended:** Run light balance monthly or when disk usage seems wrong.

---

### 3. Filesystem Usage

```bash
# Overall usage
sudo btrfs filesystem usage /

# Detailed device stats
sudo btrfs filesystem df /

# Show all subvolumes with size
sudo btrfs subvolume list /

# Disk usage per subvolume (slow but accurate)
sudo btrfs filesystem du -s /.snapshots/*/snapshot | head -20
```

---

### 4. Defragmentation

Btrfs can fragment over time, especially with databases and VMs.

```bash
# Defrag a specific file
sudo btrfs filesystem defragment /path/to/file

# Defrag directory recursively
sudo btrfs filesystem defragment -r ~/Documents

# Defrag with compression
sudo btrfs filesystem defragment -r -czstd /path/
```

**Warning:** Defrag breaks reflinks (snapshots will use more space). Don't defrag snapshotted data unless necessary.

---

### 5. Device Statistics (Error Check)

```bash
# Show device error counters
sudo btrfs device stats /

# Reset counters (after addressing issues)
sudo btrfs device stats --reset /
```

Errors indicate potential hardware issues. If non-zero, investigate immediately.

---

## Subvolume Management

### List All Subvolumes

```bash
sudo btrfs subvolume list /
sudo btrfs subvolume list -t /  # Table format
```

### Create New Subvolume

```bash
# Mount top-level first
sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt

# Create subvolume
sudo btrfs subvolume create /mnt/@newsubvol

# Unmount
sudo umount /mnt
```

### Delete Subvolume

```bash
# Delete directly (if mounted)
sudo btrfs subvolume delete /path/to/subvolume

# Or from top-level
sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt
sudo btrfs subvolume delete /mnt/@subvolname
sudo umount /mnt
```

### Snapshot Operations

```bash
# Create snapshot
sudo btrfs subvolume snapshot /source /destination

# Create read-only snapshot
sudo btrfs subvolume snapshot -r /source /destination

# Make snapshot writable
sudo btrfs property set /path/to/snapshot ro false
```

---

## Space Reclamation

### After Deleting Snapshots

Space isn't freed immediately. To reclaim:

```bash
# Sync filesystem
sudo btrfs filesystem sync /

# Run balance to reclaim chunks
sudo btrfs balance start -dusage=0 /
sudo btrfs balance start -musage=0 /
```

### Clear Orphaned Subvolumes

```bash
# List subvolumes
sudo btrfs subvolume list /

# Delete any orphaned ones
sudo btrfs subvolume delete /path/to/orphan
```

---

## Compression

### Check Current Compression

```bash
# See mount options
mount | grep btrfs

# Check compression ratio for a file
sudo compsize /path/to/file

# Install compsize if needed
sudo pacman -S compsize
```

### Enable Compression

Add to `/etc/fstab`:
```
compress=zstd:3
```

Or remount:
```bash
sudo mount -o remount,compress=zstd /
```

---

## Automated Maintenance Script

```bash
#!/bin/bash
# /usr/local/bin/btrfs-maintenance

set -e

echo "=== Btrfs Maintenance $(date) ==="

echo "1. Checking device stats..."
btrfs device stats / | grep -v "0$" && echo "WARNING: Errors detected!" || echo "No errors."

echo "2. Starting scrub..."
btrfs scrub start -B /  # -B = foreground, wait for completion

echo "3. Light balance..."
btrfs balance start -musage=50 -dusage=50 /

echo "4. Filesystem usage:"
btrfs filesystem usage /

echo "=== Maintenance complete ==="
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/btrfs-maintenance

# Create monthly timer
sudo tee /etc/systemd/system/btrfs-maintenance.service << 'EOF'
[Unit]
Description=Btrfs Monthly Maintenance

[Service]
Type=oneshot
ExecStart=/usr/local/bin/btrfs-maintenance
Nice=19
IOSchedulingClass=idle
EOF

sudo tee /etc/systemd/system/btrfs-maintenance.timer << 'EOF'
[Unit]
Description=Monthly Btrfs Maintenance

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl enable btrfs-maintenance.timer
```

---

## Troubleshooting

### Filesystem Shows Wrong Free Space

```bash
# Sync pending writes
sudo sync
sudo btrfs filesystem sync /

# Check actual usage
sudo btrfs filesystem usage /

# Run balance
sudo btrfs balance start -dusage=0 /
```

### Scrub Finds Errors

```bash
# Check device stats for hardware errors
sudo btrfs device stats /

# If errors, check dmesg
sudo dmesg | grep -i btrfs

# Consider running memtest and disk diagnostics
```

### Subvolume Delete Fails

```bash
# Check if in use
sudo lsof +D /path/to/subvolume

# Check if mounted
mount | grep subvolume

# Force delete (careful!)
sudo btrfs subvolume delete -c /path/to/subvolume
```

---

## Quick Reference

```bash
# Usage
sudo btrfs filesystem usage /

# Scrub
sudo btrfs scrub start /
sudo btrfs scrub status /

# Balance
sudo btrfs balance start -musage=50 /
sudo btrfs balance status /

# Device errors
sudo btrfs device stats /

# Subvolumes
sudo btrfs subvolume list /
sudo btrfs subvolume create /path
sudo btrfs subvolume delete /path
sudo btrfs subvolume snapshot /src /dest
```
