#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 3: System Configuration (X250)
# ============================================================
# Run this inside arch-chroot /mnt
# ============================================================

set -e
source "$(dirname "$0")/00-vars.sh"

echo "=============================================="
echo "Arch Linux Installation - Configuration (X250)"
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

# Boot entries (kernels stay in /boot/ — no multi-system EFI layout)
MICROCODE="${CPU_VENDOR}-ucode.img"

cat > /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$MICROCODE
initrd  /initramfs-linux.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rootflags=subvol=@arch rw
EOF

cat > /boot/loader/entries/arch-lts.conf << EOF
title   Arch Linux LTS
linux   /vmlinuz-linux-lts
initrd  /$MICROCODE
initrd  /initramfs-linux-lts.img
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
linux   /vmlinuz-linux
initrd  /$MICROCODE
initrd  /initramfs-linux.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rd.luks.key=$LUKS_UUID=/luks-keyfile.bin:UUID=$EFI_UUID rd.luks.options=$LUKS_UUID=keyfile-timeout=5s rootflags=subvol=@arch rw
EOF

cat > /boot/loader/entries/arch-lts.conf << EOF
title   Arch Linux LTS
linux   /vmlinuz-linux-lts
initrd  /$MICROCODE
initrd  /initramfs-linux-lts.img
options rd.luks.name=$LUKS_UUID=$CRYPT_NAME root=/dev/mapper/$CRYPT_NAME rd.luks.key=$LUKS_UUID=/luks-keyfile.bin:UUID=$EFI_UUID rd.luks.options=$LUKS_UUID=keyfile-timeout=5s rootflags=subvol=@arch rw
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

# Enable sudo for wheel (drop-in file, not appending to /etc/sudoers)
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# === SSH server ===
echo "Configuring SSH..."
systemctl enable sshd

# Install X1 public key for user tt
mkdir -p /home/"$USERNAME"/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAEUKKKwN8Pip2JPICt7HGERL/zdhgqxQPSu9jIHYITf tt@x1" > /home/"$USERNAME"/.ssh/authorized_keys
chmod 700 /home/"$USERNAME"/.ssh
chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh

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
echo "After reboot, login as $USERNAME and run 04-post-boot.sh"
echo "=============================================="
