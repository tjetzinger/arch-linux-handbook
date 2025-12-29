#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 1: Disk Partitioning
# ============================================================
# Run this from the Arch ISO live environment.
# This script will DESTROY all data on the target disk.
# ============================================================

set -e
source "$(dirname "$0")/00-vars.sh"

echo "=============================================="
echo "Arch Linux Installation - Disk Setup"
echo "=============================================="
echo ""
echo "Target disk: $DISK"
echo "This will DESTROY ALL DATA on $DISK"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm
[[ "$confirm" != "yes" ]] && echo "Aborted." && exit 1

# Validate config
validate_config || exit 1

# === Connect to WiFi if needed ===
if [[ -n "$WIFI_SSID" ]]; then
    echo "Connecting to WiFi..."
    iwctl --passphrase="$WIFI_PASS" station wlan0 connect "$WIFI_SSID"
    sleep 5
fi

# Verify internet
echo "Checking internet connection..."
ping -c 3 archlinux.org || { echo "ERROR: No internet connection"; exit 1; }

# Update system clock
timedatectl set-ntp true

# === Unmount existing ===
echo "Unmounting any existing mounts..."
umount -R /mnt 2>/dev/null || true
cryptsetup close $CRYPT_NAME 2>/dev/null || true

# === Partition disk ===
echo "Partitioning $DISK..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary 513MiB 100%

# Verify
echo "Partition layout:"
lsblk "$DISK"

# === Format EFI ===
echo "Formatting EFI partition..."
mkfs.fat -F32 "$EFI_PART"

# === LUKS encryption ===
echo ""
echo "Setting up LUKS encryption..."
echo "You will be prompted to create a LUKS password."
echo ""

cryptsetup luksFormat \
    --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha256 \
    --pbkdf argon2id \
    --pbkdf-memory 1048576 \
    --pbkdf-parallel 4 \
    --sector-size 4096 \
    "$ROOT_PART"

# Open LUKS
echo ""
echo "Opening LUKS device..."
cryptsetup open "$ROOT_PART" "$CRYPT_NAME"

# === Create Btrfs ===
echo "Creating Btrfs filesystem..."
mkfs.btrfs /dev/mapper/"$CRYPT_NAME"

# === Create subvolumes ===
echo "Creating subvolumes..."
mount /dev/mapper/"$CRYPT_NAME" /mnt

for subvol in "${SUBVOLUMES[@]}"; do
    echo "  Creating $subvol"
    btrfs subvolume create "/mnt/$subvol"
done

btrfs subvolume list /mnt
umount /mnt

# === Mount subvolumes ===
echo "Mounting subvolumes..."

# Root
mount -o "$MOUNT_OPTS,subvol=@arch" /dev/mapper/"$CRYPT_NAME" /mnt

# Create mount points
mkdir -p /mnt/{boot,.snapshots,home,var/log,var/cache,var/tmp,mnt/vm,mnt/arch-live}

# Mount others
mount -o "$MOUNT_OPTS,subvol=@.snapshots" /dev/mapper/"$CRYPT_NAME" /mnt/.snapshots
mount -o "$MOUNT_OPTS,subvol=@home" /dev/mapper/"$CRYPT_NAME" /mnt/home
mount -o "$MOUNT_OPTS,subvol=@log" /dev/mapper/"$CRYPT_NAME" /mnt/var/log
mount -o "$MOUNT_OPTS,subvol=@cache" /dev/mapper/"$CRYPT_NAME" /mnt/var/cache
mount -o "$MOUNT_OPTS,subvol=@tmp" /dev/mapper/"$CRYPT_NAME" /mnt/var/tmp
mount -o "$MOUNT_OPTS,subvol=@arch-live" /dev/mapper/"$CRYPT_NAME" /mnt/mnt/arch-live

# VMs with nodatacow
mount -o "$MOUNT_OPTS_NODATACOW,subvol=@vm" /dev/mapper/"$CRYPT_NAME" /mnt/mnt/vm

# EFI
mount "$EFI_PART" /mnt/boot

# Verify mounts
echo ""
echo "Mount points:"
mount | grep /mnt

echo ""
echo "=============================================="
echo "Disk setup complete!"
echo "Run 02-install.sh to continue installation."
echo "=============================================="
