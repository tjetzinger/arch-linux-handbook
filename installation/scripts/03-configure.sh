#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 3: System Configuration
# ============================================================
# Run this inside arch-chroot /mnt
# ============================================================

set -e
source "$(dirname "$0")/00-vars.sh"

echo "=============================================="
echo "Arch Linux Installation - Configuration"
echo "=============================================="

# === Timezone ===
echo "Setting timezone to $TIMEZONE..."
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# === Locale ===
echo "Configuring locale..."
echo "$LOCALE UTF-8" >> /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# === Hostname ===
echo "Setting hostname to $HOSTNAME..."
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# === mkinitcpio ===
echo "Configuring mkinitcpio..."
cat > /etc/mkinitcpio.conf << EOF
MODULES=($MKINITCPIO_MODULES)
BINARIES=(/usr/bin/btrfs)
FILES=()
HOOKS=($MKINITCPIO_HOOKS)
EOF

echo "Generating initramfs..."
mkinitcpio -P

# === systemd-boot ===
echo "Installing systemd-boot..."
bootctl install

# Loader config
cat > /boot/loader/loader.conf << 'EOF'
default arch.conf
timeout 3
console-mode max
editor no
EOF

# Get UUIDs
LUKS_UUID=$(blkid -s UUID -o value "$ROOT_PART")
EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")

echo "LUKS UUID: $LUKS_UUID"
echo "EFI UUID: $EFI_UUID"

# Organize kernel files
mkdir -p /boot/EFI/arch
mv /boot/vmlinuz-linux /boot/EFI/arch/ 2>/dev/null || true
mv /boot/vmlinuz-linux-lts /boot/EFI/arch/ 2>/dev/null || true
mv /boot/initramfs-linux.img /boot/EFI/arch/ 2>/dev/null || true
mv /boot/initramfs-linux-lts.img /boot/EFI/arch/ 2>/dev/null || true
mv /boot/initramfs-linux-fallback.img /boot/EFI/arch/ 2>/dev/null || true
mv /boot/initramfs-linux-lts-fallback.img /boot/EFI/arch/ 2>/dev/null || true

# Boot entries
MICROCODE="${CPU_VENDOR}-ucode.img"

cat > /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /EFI/arch/vmlinuz-linux
initrd  /$MICROCODE
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rootflags=subvol=@arch rw
EOF

cat > /boot/loader/entries/arch-lts.conf << EOF
title   Arch Linux LTS
linux   /EFI/arch/vmlinuz-linux-lts
initrd  /$MICROCODE
initrd  /EFI/arch/initramfs-linux-lts.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rootflags=subvol=@arch rw
EOF

# === LUKS keyfile ===
echo "Creating LUKS keyfile for auto-unlock..."
dd bs=512 count=8 if=/dev/urandom of=/boot/luks-keyfile.bin 2>/dev/null
chmod 400 /boot/luks-keyfile.bin

echo ""
echo "Adding keyfile to LUKS (enter LUKS password):"
cryptsetup luksAddKey "$ROOT_PART" /boot/luks-keyfile.bin

# Update boot entries with keyfile
cat > /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /EFI/arch/vmlinuz-linux
initrd  /$MICROCODE
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rd.luks.key=$LUKS_UUID=/luks-keyfile.bin:UUID=$EFI_UUID rd.luks.options=$LUKS_UUID=keyfile-timeout=5s rootflags=subvol=@arch rw
EOF

cat > /boot/loader/entries/arch-lts.conf << EOF
title   Arch Linux LTS
linux   /EFI/arch/vmlinuz-linux-lts
initrd  /$MICROCODE
initrd  /EFI/arch/initramfs-linux-lts.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rd.luks.key=$LUKS_UUID=/luks-keyfile.bin:UUID=$EFI_UUID rd.luks.options=$LUKS_UUID=keyfile-timeout=5s rootflags=subvol=@arch rw
EOF

# Recovery entry
cat > /boot/loader/entries/arch-live.conf << EOF
title   Arch Linux Live (Recovery)
linux   /EFI/arch-live/vmlinuz-linux
initrd  /$MICROCODE
initrd  /EFI/arch-live/initramfs-linux.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rd.luks.key=$LUKS_UUID=/luks-keyfile.bin:UUID=$EFI_UUID rd.luks.options=$LUKS_UUID=keyfile-timeout=5s rootflags=subvol=@arch-live rw
EOF

# === Root password ===
echo ""
echo "Set root password:"
passwd

# === Create user ===
echo "Creating user $USERNAME..."
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "Set password for $USERNAME:"
passwd "$USERNAME"

# Enable sudo for wheel
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# === Enable services ===
echo "Enabling services..."
systemctl enable NetworkManager
systemctl enable fstrim.timer

# === Pacman hook for bootloader ===
mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/100-systemd-boot.hook << 'EOF'
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF

echo ""
echo "=============================================="
echo "Configuration complete!"
echo ""
echo "Next steps:"
echo "  1. exit (leave chroot)"
echo "  2. umount -R /mnt"
echo "  3. reboot"
echo ""
echo "After reboot, login and run 04-desktop.sh"
echo "=============================================="
