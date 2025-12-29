# 02 - Disk Setup

Partitioning, LUKS encryption, and Btrfs subvolume creation.

## Partition Layout

| Partition | Size | Type | Filesystem | Mount |
|-----------|------|------|------------|-------|
| EFI (p1) | 512 MB - 1 GB | EFI System | FAT32 | `/boot` |
| Root (p2) | Remaining | Linux filesystem | LUKS2 → Btrfs | `/` |

**Note:** Swap is handled via zram or swapfile, not a separate partition.

---

## Step 1: Partition the Disk

### Using fdisk

```bash
DISK="/dev/nvme0n1"

# Start fdisk
fdisk $DISK
```

Inside fdisk:
```
g          # Create new GPT partition table
n          # New partition (EFI)
1          # Partition number 1
[Enter]    # Default first sector
+512M      # Size 512MB
t          # Change type
1          # EFI System

n          # New partition (Root)
2          # Partition number 2
[Enter]    # Default first sector
[Enter]    # Use remaining space
           # Type is already Linux filesystem

p          # Print to verify
w          # Write and exit
```

### Using parted (Alternative)

```bash
DISK="/dev/nvme0n1"

parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary 513MiB 100%
```

### Verify Partitions

```bash
lsblk $DISK
# Should show:
# nvme0n1
# ├─nvme0n1p1   512M
# └─nvme0n1p2   (rest)
```

---

## Step 2: Format EFI Partition

```bash
EFI_PART="/dev/nvme0n1p1"

mkfs.fat -F32 $EFI_PART
```

---

## Step 3: Setup LUKS Encryption

### Create LUKS2 Container

```bash
ROOT_PART="/dev/nvme0n1p2"

# LUKS2 with optimized settings for NVMe
cryptsetup luksFormat \
    --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha256 \
    --pbkdf argon2id \
    --pbkdf-memory 1048576 \
    --pbkdf-parallel 4 \
    --sector-size 4096 \
    $ROOT_PART
```

**Options explained:**
| Option | Value | Purpose |
|--------|-------|---------|
| `--type luks2` | LUKS version 2 | Modern format, supports argon2 |
| `--cipher aes-xts-plain64` | AES-XTS | Standard disk encryption |
| `--key-size 512` | 512 bits | 256-bit AES (XTS doubles it) |
| `--pbkdf argon2id` | Argon2id | Memory-hard KDF (resists GPU attacks) |
| `--pbkdf-memory 1048576` | 1 GB | Memory cost (adjust for your RAM) |
| `--sector-size 4096` | 4K sectors | Matches NVMe native sector size |

### Open LUKS Container

```bash
CRYPT_NAME="cryptroot"

cryptsetup open $ROOT_PART $CRYPT_NAME

# Verify
ls /dev/mapper/$CRYPT_NAME
```

---

## Step 4: Create Btrfs Filesystem

```bash
mkfs.btrfs /dev/mapper/cryptroot
```

---

## Step 5: Create Subvolumes

### Mount Top-Level

```bash
mount /dev/mapper/cryptroot /mnt
```

### Create Subvolume Structure

```bash
# Main system
btrfs subvolume create /mnt/@arch

# Snapper snapshots (required for snapper)
btrfs subvolume create /mnt/@.snapshots

# Optional: Separate subvolumes to exclude from root snapshots
btrfs subvolume create /mnt/@home      # User data
btrfs subvolume create /mnt/@log       # /var/log
btrfs subvolume create /mnt/@cache     # /var/cache
btrfs subvolume create /mnt/@tmp       # /var/tmp

# Optional: Special purpose
btrfs subvolume create /mnt/@vm        # VMs (will use nodatacow)
btrfs subvolume create /mnt/@arch-live # Recovery environment

# Verify
btrfs subvolume list /mnt
```

### Subvolume Purpose

| Subvolume | Mount Point | Snapshotted | Notes |
|-----------|-------------|-------------|-------|
| `@arch` | `/` | Yes | Main system |
| `@.snapshots` | `/.snapshots` | No | Snapper metadata |
| `@home` | `/home` | Optional | User data |
| `@log` | `/var/log` | No | Logs persist across rollback |
| `@cache` | `/var/cache` | No | Rebuild-able |
| `@tmp` | `/var/tmp` | No | Temporary files |
| `@vm` | `/mnt/vm` | No | VMs with nodatacow |
| `@arch-live` | `/mnt/arch-live` | No | Recovery system |

### Unmount Top-Level

```bash
umount /mnt
```

---

## Step 6: Mount Subvolumes

### Mount Options

```bash
MOUNT_OPTS="rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"
```

| Option | Purpose |
|--------|---------|
| `noatime` | Don't update access times (performance) |
| `compress=zstd:3` | Transparent compression |
| `ssd` | SSD optimizations |
| `discard=async` | TRIM support (async for performance) |
| `space_cache=v2` | Improved space cache |

### Mount Subvolumes

```bash
# Root
mount -o $MOUNT_OPTS,subvol=@arch /dev/mapper/cryptroot /mnt

# Create mount points
mkdir -p /mnt/{boot,.snapshots,home,var/log,var/cache,var/tmp,mnt/vm,mnt/arch-live}

# Mount others
mount -o $MOUNT_OPTS,subvol=@.snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o $MOUNT_OPTS,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o $MOUNT_OPTS,subvol=@log /dev/mapper/cryptroot /mnt/var/log
mount -o $MOUNT_OPTS,subvol=@cache /dev/mapper/cryptroot /mnt/var/cache
mount -o $MOUNT_OPTS,subvol=@tmp /dev/mapper/cryptroot /mnt/var/tmp
mount -o $MOUNT_OPTS,subvol=@arch-live /dev/mapper/cryptroot /mnt/mnt/arch-live

# VMs with nodatacow
mount -o rw,noatime,nodatacow,ssd,discard=async,space_cache=v2,subvol=@vm /dev/mapper/cryptroot /mnt/mnt/vm

# EFI partition
mount /dev/nvme0n1p1 /mnt/boot
```

### Verify Mounts

```bash
lsblk -f
mount | grep /mnt
```

Expected output:
```
/dev/mapper/cryptroot on /mnt type btrfs (rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@arch)
/dev/mapper/cryptroot on /mnt/.snapshots type btrfs (...,subvol=/@.snapshots)
/dev/mapper/cryptroot on /mnt/home type btrfs (...,subvol=/@home)
...
/dev/nvme0n1p1 on /mnt/boot type vfat (...)
```

---

## Quick Reference

```bash
# Variables
DISK="/dev/nvme0n1"
EFI_PART="/dev/nvme0n1p1"
ROOT_PART="/dev/nvme0n1p2"
CRYPT_NAME="cryptroot"
MOUNT_OPTS="rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

# Partition
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary 513MiB 100%

# Format EFI
mkfs.fat -F32 $EFI_PART

# LUKS
cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 --key-size 512 \
    --pbkdf argon2id --pbkdf-memory 1048576 --sector-size 4096 $ROOT_PART
cryptsetup open $ROOT_PART $CRYPT_NAME

# Btrfs
mkfs.btrfs /dev/mapper/$CRYPT_NAME
mount /dev/mapper/$CRYPT_NAME /mnt
btrfs subvolume create /mnt/@arch
btrfs subvolume create /mnt/@.snapshots
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@vm
btrfs subvolume create /mnt/@arch-live
umount /mnt

# Mount
mount -o $MOUNT_OPTS,subvol=@arch /dev/mapper/$CRYPT_NAME /mnt
mkdir -p /mnt/{boot,.snapshots,home,var/log,var/cache,mnt/vm,mnt/arch-live}
mount -o $MOUNT_OPTS,subvol=@.snapshots /dev/mapper/$CRYPT_NAME /mnt/.snapshots
mount -o $MOUNT_OPTS,subvol=@home /dev/mapper/$CRYPT_NAME /mnt/home
mount -o $MOUNT_OPTS,subvol=@log /dev/mapper/$CRYPT_NAME /mnt/var/log
mount -o $MOUNT_OPTS,subvol=@cache /dev/mapper/$CRYPT_NAME /mnt/var/cache
mount -o rw,noatime,nodatacow,ssd,discard=async,space_cache=v2,subvol=@vm /dev/mapper/$CRYPT_NAME /mnt/mnt/vm
mount -o $MOUNT_OPTS,subvol=@arch-live /dev/mapper/$CRYPT_NAME /mnt/mnt/arch-live
mount $EFI_PART /mnt/boot
```

---

## Next Step

Proceed to [03-BASE-INSTALL.md](./03-BASE-INSTALL.md) for base system installation.
