# Btrfs Subvolume Strategy

Guide for planning and managing Btrfs subvolumes for optimal snapshot and backup efficiency.

## Current Layout

```
Top-level (subvolid=5)
├── @arch          → /              (snapshotted)
│   ├── var/lib/portables          (nested subvol)
│   └── var/lib/machines           (nested subvol)
├── @arch-live     → /mnt/arch-live (not snapshotted)
├── @Documents     → /home/tt/Documents (not snapshotted by root config)
├── @.snapshots    → /.snapshots    (snapper metadata)
└── @vm            → /mnt/vm        (not snapshotted)
```

---

## Why Separate Subvolumes?

| Reason | Example |
|--------|---------|
| **Exclude from snapshots** | VMs, downloads, caches |
| **Different backup policies** | Documents daily, system weekly |
| **Different mount options** | nodatacow for VMs |
| **Easy reinstall** | Keep /home, reinstall root |
| **Space management** | Quotas per subvolume |

---

## Recommended Layout

### Essential Subvolumes

| Subvolume | Mount | Snapshot | Reason |
|-----------|-------|----------|--------|
| `@` or `@arch` | `/` | Yes | Core system |
| `@home` | `/home` | Optional | User data (consider separate snapper config) |
| `@.snapshots` | `/.snapshots` | No | Snapper metadata |
| `@log` | `/var/log` | No | Logs shouldn't rollback |
| `@cache` | `/var/cache` | No | Rebuild-able |
| `@tmp` | `/var/tmp` | No | Temporary files |

### Optional Subvolumes

| Subvolume | Mount | Use Case |
|-----------|-------|----------|
| `@vm` | `/var/lib/libvirt` | Virtual machines |
| `@docker` | `/var/lib/docker` | Docker storage |
| `@containers` | `/var/lib/containers` | Podman storage |
| `@swap` | `/swap` | Swapfile (needs nodatacow) |
| `@Documents` | `~/Documents` | Important files with separate backup |
| `@Downloads` | `~/Downloads` | Exclude from backups |
| `@games` | `~/Games` or `/opt/games` | Steam, large games |

---

## Creating New Subvolumes

### Method 1: From Running System

```bash
# 1. Mount top-level
sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt

# 2. Create subvolume
sudo btrfs subvolume create /mnt/@newsubvol

# 3. Move existing data (if any)
sudo mv /path/to/existing/data /mnt/@newsubvol/

# 4. Unmount
sudo umount /mnt

# 5. Add to fstab
echo "UUID=7baf5627-b3c5-4add-8b0e-fdd3488f00e0  /mount/point  btrfs  rw,relatime,ssd,discard,space_cache=v2,subvol=/@newsubvol  0 0" | sudo tee -a /etc/fstab

# 6. Create mount point and mount
sudo mkdir -p /mount/point
sudo mount /mount/point
```

### Method 2: During Fresh Install

```bash
# After creating btrfs filesystem
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@.snapshots
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@vm
umount /mnt

# Mount with subvolumes
mount -o subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,.snapshots,var/log,var/cache,mnt/vm,boot}
mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o subvol=@.snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o subvol=@log /dev/mapper/cryptroot /mnt/var/log
mount -o subvol=@cache /dev/mapper/cryptroot /mnt/var/cache
mount -o subvol=@vm /dev/mapper/cryptroot /mnt/mnt/vm
```

---

## Special Mount Options

### For VMs and Databases (nodatacow)

Disable copy-on-write for better performance with large files that change frequently:

```bash
# In fstab, add nodatacow
UUID=... /mnt/vm btrfs rw,nodatacow,subvol=/@vm 0 0

# Or set attribute on directory
sudo chattr +C /mnt/vm

# Verify
lsattr /mnt/vm
```

**Note:** nodatacow disables checksums and compression for that subvolume.

### For Swap

```bash
# Create swap subvolume
sudo btrfs subvolume create /mnt/@swap

# Mount with nodatacow
# In fstab:
UUID=... /swap btrfs rw,nodatacow,subvol=/@swap 0 0

# Create swapfile
sudo truncate -s 0 /swap/swapfile
sudo chattr +C /swap/swapfile
sudo fallocate -l 16G /swap/swapfile
sudo chmod 600 /swap/swapfile
sudo mkswap /swap/swapfile
sudo swapon /swap/swapfile

# Add to fstab
echo "/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
```

---

## Snapshot Configuration per Subvolume

### Create Separate Snapper Config for Home

```bash
# Create snapper config for @home
sudo snapper -c home create-config /home

# Edit config
sudo vim /etc/snapper/configs/home

# Key settings:
TIMELINE_CREATE="yes"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
```

### Subvolumes That Shouldn't Be Snapshotted

Configure snapper to skip nested subvolumes automatically, or ensure they're mounted separately.

Add to `/etc/snapper/configs/root`:
```
# Files/directories to skip
ALLOW_GROUPS=""
ALLOW_USERS=""
```

---

## Migration: Split Existing Directory to Subvolume

Example: Move `/var/log` to its own subvolume.

```bash
# 1. Boot to arch-live (or do carefully on running system)
cryptsetup open /dev/nvme0n1p2 cryptroot
mount -o subvolid=5 /dev/mapper/cryptroot /mnt

# 2. Create new subvolume
btrfs subvolume create /mnt/@log

# 3. Copy data
cp -a /mnt/@arch/var/log/* /mnt/@log/

# 4. Clear original directory
rm -rf /mnt/@arch/var/log/*

# 5. Unmount
umount /mnt

# 6. Update fstab (from chroot or running system)
echo "UUID=7baf5627-b3c5-4add-8b0e-fdd3488f00e0  /var/log  btrfs  rw,relatime,ssd,discard,space_cache=v2,subvol=/@log  0 0" >> /etc/fstab

# 7. Mount new subvolume
mount /var/log
```

---

## Nested vs Flat Subvolumes

### Flat Layout (Recommended)

All subvolumes at top-level:

```
subvolid=5
├── @arch
├── @home
├── @log
├── @.snapshots
└── @vm
```

**Advantages:**
- Snapshots of @arch don't include @home, @log, etc.
- Clear separation
- Easy to manage

### Nested Layout

Subvolumes inside other subvolumes:

```
subvolid=5
└── @arch
    ├── home (subvolume)
    └── var/log (subvolume)
```

**Disadvantages:**
- Snapshots include empty mount points
- More complex management
- Can cause confusion during recovery

---

## Quotas (Optional)

Limit space per subvolume:

```bash
# Enable quotas
sudo btrfs quota enable /

# Set quota on subvolume
sudo btrfs qgroup limit 100G /home/tt/Downloads

# Check usage
sudo btrfs qgroup show /
```

---

## Your Current Setup Analysis

| Subvolume | Status | Recommendation |
|-----------|--------|----------------|
| `@arch` | Snapshotted | Good |
| `@.snapshots` | Snapper managed | Good |
| `@Documents` | Not snapshotted | Consider snapper config or borg |
| `@vm` | Not snapshotted | Good (VMs are large) |
| `@arch-live` | Not snapshotted | Good (separate system) |
| `/var/log` | Inside @arch | Consider separate subvol |
| `/var/cache` | Inside @arch | Consider separate subvol |
| `/home` | Inside @arch | Consider @home subvol |

### Potential Improvements

1. **Add @home subvolume** - Keep user data separate from root
2. **Add @log subvolume** - Prevent log loss on rollback
3. **Add @cache subvolume** - Exclude from snapshots
4. **Add snapper config for Documents** - If you want versioned Documents

---

## Quick Reference

```bash
# List subvolumes
sudo btrfs subvolume list /

# Create subvolume (mount top-level first)
sudo btrfs subvolume create /mnt/@newsubvol

# Delete subvolume
sudo btrfs subvolume delete /path/to/subvol

# Get subvolume ID
sudo btrfs subvolume show /path

# Snapshot
sudo btrfs subvolume snapshot /source /dest
sudo btrfs subvolume snapshot -r /source /dest  # read-only

# Set nodatacow
sudo chattr +C /path/to/dir
```
