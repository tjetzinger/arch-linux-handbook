#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 2: Base Installation (X250)
# ============================================================
# Run this after 01-partition.sh
# ============================================================

set -e
source "$(dirname "$0")/00-vars.sh"

echo "=============================================="
echo "Arch Linux Installation - Base System (X250)"
echo "=============================================="

# Verify mounts
if ! mountpoint -q /mnt; then
    echo "ERROR: /mnt is not mounted. Run 01-partition.sh first."
    exit 1
fi

# === Update mirrors ===
echo "Updating mirror list..."
reflector --country Germany,Austria,Switzerland,Netherlands \
          --protocol https \
          --age 12 \
          --sort rate \
          --save /etc/pacman.d/mirrorlist

# === Install base system ===
echo "Installing base packages..."
pacstrap -K /mnt "${BASE_PACKAGES[@]}"

# === Generate fstab ===
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "fstab contents:"
cat /mnt/etc/fstab

# === Copy scripts to new system ===
echo "Copying installation scripts..."
mkdir -p /mnt/root/install
cp "$(dirname "$0")"/*.sh /mnt/root/install/
chmod +x /mnt/root/install/*.sh

echo ""
echo "=============================================="
echo "Base installation complete!"
echo ""
echo "Next steps:"
echo "  1. arch-chroot /mnt"
echo "  2. cd /root/install"
echo "  3. ./03-configure.sh"
echo "=============================================="
