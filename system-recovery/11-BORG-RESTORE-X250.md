# Borg Backup Recovery - ThinkPad X250

Complete guide for restoring Borg backups to ThinkPad X250 from X1 Carbon via SSH.

## Important: What's in the Backup

The Borg backup contains **data and configs only**, not a full system:

| Included | NOT Included |
|----------|--------------|
| `/home/tt` | Base system (`/usr`, `/lib`, `/bin`) |
| `/etc` | Installed packages |
| `/boot` | Package database |
| `/usr/local` | System directories |
| `/root` | |

**Recommended approach:** Install fresh base system, then restore home + configs from Borg.

---

## Target Hardware

| Component | Specification |
|-----------|---------------|
| Model | ThinkPad X250 |
| CPU | Intel Core i7 2.6 GHz |
| RAM | 8 GB |
| Storage | 250 GB SSD |
| Disk Device | `/dev/sda` (SATA SSD) |

## Prerequisites

### On X1 Carbon (Borg Server)

1. **Borg repository exists** with system backups
2. **SSH server running** and accessible from local network
3. **User with access** to Borg repository

### Verify Borg Repository

```bash
# Repository location
export BORG_REPO="/mnt/borg-backup/repo"
export BORG_PASSCOMMAND="secret-tool lookup borg repo"

# List archives
borg list $BORG_REPO
borg info $BORG_REPO
```

**Note:** Passphrase stored in GNOME Keyring via `secret-tool store --label='Borg Backup Passphrase' borg repo`

### Setup SSH Access for Borg

```bash
# Enable SSH server (if not already running)
sudo systemctl enable --now sshd

# Verify listening
ss -tlnp | grep :22

# Get IP address
ip addr show | grep "inet " | grep -v 127.0.0.1
```

---

## Restore Procedure (Recommended)

This is the tested, working approach: fresh base system + restore data from Borg.

### Step 1: Boot from Arch ISO

1. Download latest Arch Linux ISO: https://archlinux.org/download/
2. Write to USB: `dd if=archlinux.iso of=/dev/sdX bs=4M status=progress`
3. Boot X250 from USB

### Step 2: Setup Keyboard and Network

```bash
# German keyboard
loadkeys de-latin1

# WiFi
iwctl
device list
station wlan0 scan
station wlan0 connect "SSID"

# Verify
ping -c 3 archlinux.org
```

### Step 3: Partition Disk

```bash
DISK="/dev/sda"

parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary 513MiB 100%

mkfs.fat -F32 /dev/sda1
```

### Step 4: Setup LUKS Encryption

```bash
# Create LUKS container (512MB memory for 8GB RAM)
cryptsetup luksFormat \
    --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha256 \
    --pbkdf argon2id \
    --pbkdf-memory 524288 \
    --pbkdf-parallel 4 \
    /dev/sda2

# Type YES (capitals) when prompted

# Open LUKS
cryptsetup open /dev/sda2 cryptroot
```

### Step 5: Create Btrfs and Subvolumes

```bash
mkfs.btrfs /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/@arch
btrfs subvolume create /mnt/@home

umount /mnt
```

### Step 6: Mount for Installation

```bash
mount -o subvol=@arch,compress=zstd /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home}
mount -o subvol=@home,compress=zstd /dev/mapper/cryptroot /mnt/home
mount /dev/sda1 /mnt/boot
```

### Step 7: Install Base System

```bash
pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs networkmanager openssh sudo nano
```

### Step 8: Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

### Step 9: Setup SSH Key for Borg Access

```bash
# Generate temporary SSH key
ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
cat /root/.ssh/id_ed25519.pub
```

On the X1 Carbon (Borg server), add the public key:
```bash
echo "ssh-ed25519 AAAA... root@archiso" >> ~/.ssh/authorized_keys
```

### Step 10: Restore Home Directory from Borg

```bash
# Set Borg variables (replace X1_IP with actual IP)
export BORG_REPO="ssh://tt@X1_IP/mnt/borg-backup/repo"
export BORG_PASSPHRASE="your-borg-passphrase"

# Test SSH connection
ssh tt@X1_IP "echo connected"

# List archives
borg list $BORG_REPO

# Restore home directory to /mnt
cd /mnt
borg extract --progress $BORG_REPO::x1-2025-12-22_171702 home/tt

# Fix ownership
chown -R 1000:1000 /mnt/home/tt
```

### Step 11: Chroot and Configure System

```bash
arch-chroot /mnt

# Timezone
ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Keyboard
echo "KEYMAP=de-latin1" > /etc/vconsole.conf

# Hostname
echo "x250" > /etc/hostname

# Enable services
systemctl enable NetworkManager sshd
```

### Step 12: Configure mkinitcpio

```bash
nano /etc/mkinitcpio.conf
```

Set HOOKS:
```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

**Important:** Do NOT include nvidia modules (X1-specific).

```bash
mkinitcpio -P
```

### Step 13: Install Bootloader

```bash
bootctl install

# Create loader config
cat > /boot/loader/loader.conf << 'EOF'
default arch.conf
timeout 3
console-mode max
editor no
EOF

# Get LUKS UUID
LUKS_UUID=$(cryptsetup luksUUID /dev/sda2)

# Create boot entry
cat > /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options rd.luks.name=$LUKS_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@arch rw
EOF
```

### Step 14: Set Passwords and Create User

```bash
# Root password
passwd

# Create user
useradd -m -G wheel -s /bin/bash tt
passwd tt

# Enable sudo
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```

### Step 15: Exit and Reboot

```bash
exit
umount -R /mnt
reboot
```

### Step 16: Post-Reboot - Install Desktop

After booting into the new system:

```bash
# Connect to WiFi
nmcli device wifi connect "SSID" password "PASSWORD"

# Install desktop (Hyprland)
sudo pacman -S hyprland waybar wofi kitty

# Configs already restored in /home/tt
```

---

## Quick Reference

### Borg Repository

| Location | Path |
|----------|------|
| Local (on X1) | `/mnt/borg-backup/repo` |
| Remote (from X250) | `ssh://tt@X1_IP/mnt/borg-backup/repo` |
| Passphrase | GNOME Keyring: `secret-tool lookup borg repo` |

### Essential Borg Commands

```bash
# Set environment
export BORG_REPO="ssh://tt@X1_IP/mnt/borg-backup/repo"
export BORG_PASSPHRASE="your-passphrase"

# List archives
borg list $BORG_REPO

# Show archive contents
borg list $BORG_REPO::ARCHIVE_NAME | head -50

# Extract specific path
borg extract $BORG_REPO::ARCHIVE_NAME home/tt

# Mount archive for browsing
mkdir /mnt/borg
borg mount $BORG_REPO::ARCHIVE_NAME /mnt/borg
ls /mnt/borg
borg umount /mnt/borg
```

### X250 vs X1 Carbon Differences

| Aspect | X1 Carbon Gen 11 | ThinkPad X250 |
|--------|------------------|---------------|
| Disk | `/dev/nvme0n1` (NVMe) | `/dev/sda` (SATA) |
| Thunderbolt | Yes (TB4) | No |
| RAM | 32 GB | 8 GB |
| LUKS pbkdf-memory | 1048576 (1GB) | 524288 (512MB) |
| eGPU | nvidia-open | Not applicable |

---

## Troubleshooting

### SSH Connection Refused

```bash
# On X1 Carbon - check SSH is running
sudo systemctl status sshd

# Check firewall
sudo ufw status
sudo ufw allow ssh
```

### Borg Passphrase Error

```bash
# Test passphrase interactively
unset BORG_PASSPHRASE
borg list $BORG_REPO
# Enter passphrase when prompted
```

### Conflicting Files During pacstrap

If you restored Borg data before running pacstrap:
```bash
# Backup restored configs
cp -a /mnt/etc /mnt/etc.borg-backup

# Install with overwrite
pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs --overwrite '*'

# Restore needed configs
cp /mnt/etc.borg-backup/locale.conf /mnt/etc/
# etc.
```

### mkinitcpio Errors

**"module not found: nvidia"** - Remove nvidia from MODULES in `/etc/mkinitcpio.conf`

**"Invalid kernel module directory"** - Remove `/etc/mkinitcpio.d/linux-lts.preset` and `/etc/mkinitcpio-lts.conf` (X1-specific)

### Boot Fails After Restore

1. Boot from Arch ISO
2. Unlock and mount:
   ```bash
   cryptsetup open /dev/sda2 cryptroot
   mount -o subvol=@arch /dev/mapper/cryptroot /mnt
   mount /dev/sda1 /mnt/boot
   arch-chroot /mnt
   ```
3. Verify boot entry has correct LUKS UUID
4. Regenerate initramfs: `mkinitcpio -P`
5. Reinstall bootloader: `bootctl install`

---

## Lessons Learned from Testing

| Issue Encountered | Solution |
|-------------------|----------|
| Borg doesn't contain full system | Install base packages first, then restore data |
| Restored `/etc` conflicts with packages | Use `--overwrite '*'` or backup first |
| X1-specific configs (nvidia, lts) | Remove from mkinitcpio, delete lts preset |
| Kernel in wrong path (`/boot/EFI/arch/`) | Use standard `/boot/` paths |
| Wrong LUKS UUID in boot entry | Update with `blkid` output |

---

## Related

- [07-BORG-BACKUP-AUTOMATION.md](./07-BORG-BACKUP-AUTOMATION.md) - Borg backup setup
- [08-DISASTER-RECOVERY-CHECKLIST.md](./08-DISASTER-RECOVERY-CHECKLIST.md) - Recovery scenarios
- [../installation/02-DISK-SETUP.md](../installation/02-DISK-SETUP.md) - Full disk setup guide
