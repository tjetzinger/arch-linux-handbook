# 05 - System Configuration

Additional system configuration after first boot.

## Prerequisites

- Successfully booted into new system
- Logged in as root or your user with sudo

---

## Step 1: Connect to Network

### WiFi

```bash
# Using NetworkManager
nmcli device wifi list
nmcli device wifi connect "SSID" password "password"

# Or interactive
nmtui
```

### Verify

```bash
ping -c 3 archlinux.org
```

---

## Step 2: Update System

```bash
sudo pacman -Syu
```

---

## Step 3: Install Essential Packages

### System Utilities

```bash
sudo pacman -S \
    acpi \
    acpid \
    tlp \
    thermald \
    powertop \
    upower \
    smartmontools
```

### Enable Power Management

```bash
sudo systemctl enable acpid
sudo systemctl enable tlp
sudo systemctl enable thermald
```

### Hardware Support

```bash
sudo pacman -S \
    alsa-utils \
    pulseaudio \
    pulseaudio-alsa \
    pavucontrol \
    bluez \
    bluez-utils
```

### Enable Bluetooth

```bash
sudo systemctl enable bluetooth
```

---

## Step 4: Configure Zram (Swap)

Zram provides compressed RAM-based swap, better than swap files for SSDs.

```bash
# Install zram-generator
sudo pacman -S zram-generator

# Configure
sudo tee /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
EOF

# Reboot to activate, or:
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service

# Verify
zramctl
swapon --show
```

---

## Step 5: Set Up Firewall

```bash
# Install
sudo pacman -S ufw

# Configure
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# Enable service
sudo systemctl enable ufw

# Check status
sudo ufw status
```

---

## Step 6: Configure Pacman

### Edit pacman.conf

```bash
sudo vim /etc/pacman.conf
```

Uncomment/add:
```ini
# Misc options
Color
ParallelDownloads = 5
ILoveCandy

# Enable multilib (for 32-bit packages, gaming)
[multilib]
Include = /etc/pacman.d/mirrorlist
```

### Update

```bash
sudo pacman -Syu
```

---

## Step 7: Set Up Reflector (Mirror Updates)

```bash
# Install
sudo pacman -S reflector

# Configure
sudo tee /etc/xdg/reflector/reflector.conf << 'EOF'
--save /etc/pacman.d/mirrorlist
--protocol https
--country Germany,Austria,Switzerland,Netherlands
--latest 10
--sort rate
EOF

# Enable timer
sudo systemctl enable reflector.timer
```

---

## Step 8: Install Shell Environment

### Zsh

```bash
sudo pacman -S zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions

# Change default shell
chsh -s /bin/zsh
```

### Oh-My-Zsh (Optional)

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

## Step 9: SSH Configuration (Optional)

```bash
# Install
sudo pacman -S openssh

# Enable
sudo systemctl enable sshd

# Configure (optional)
sudo vim /etc/ssh/sshd_config
# Recommended: PasswordAuthentication no (use keys)
```

---

## Step 10: Time Synchronization

```bash
# Already enabled by default, verify
timedatectl status

# If not enabled
sudo timedatectl set-ntp true
```

---

## Step 11: SSD Optimization

### Verify TRIM

```bash
# Check TRIM support
lsblk --discard

# Timer should already be enabled, verify
systemctl status fstrim.timer
```

### I/O Scheduler

For NVMe SSDs, `none` scheduler is optimal:

```bash
cat /sys/block/nvme0n1/queue/scheduler
# Should show [none]
```

---

## Step 12: Install AUR Helper

### Install yay

```bash
# As regular user, not root
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin
```

### Usage

```bash
# Search
yay -Ss package-name

# Install
yay -S package-name

# Update all (including AUR)
yay -Syu
```

---

## Step 13: Set Up Recovery Environment (arch-live)

Install a minimal system for recovery:

```bash
# Mount arch-live subvolume
sudo mount -o subvol=@arch-live /dev/mapper/cryptroot /mnt/arch-live

# Install minimal base
sudo pacstrap /mnt/arch-live base linux linux-firmware btrfs-progs vim networkmanager

# Create fstab for it
sudo genfstab -U /mnt/arch-live >> /mnt/arch-live/etc/fstab

# Configure minimal system
sudo arch-chroot /mnt/arch-live /bin/bash << 'EOF'
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch-live" > /etc/hostname
passwd  # Set a simple password for emergency
systemctl enable NetworkManager
EOF

# Copy kernel to EFI
sudo mkdir -p /boot/EFI/arch-live
sudo cp /mnt/arch-live/boot/vmlinuz-linux /boot/EFI/arch-live/
sudo cp /mnt/arch-live/boot/initramfs-linux.img /boot/EFI/arch-live/

# Unmount
sudo umount /mnt/arch-live
```

Boot entry already created in 04-BOOTLOADER.md.

---

## Security Hardening (Optional)

### Restrict Core Dumps

```bash
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
```

### Kernel Parameters

```bash
sudo tee /etc/sysctl.d/99-security.conf << 'EOF'
# Restrict kernel pointer exposure
kernel.kptr_restrict = 2

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Disable magic SysRq key
kernel.sysrq = 0

# Network hardening
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF

sudo sysctl --system
```

---

## Quick Reference

```bash
# Essential packages
sudo pacman -S acpi acpid tlp thermald powertop alsa-utils pulseaudio bluez bluez-utils

# Enable services
sudo systemctl enable acpid tlp thermald bluetooth fstrim.timer

# Zram
sudo pacman -S zram-generator
echo -e "[zram0]\nzram-size = min(ram / 2, 8192)\ncompression-algorithm = zstd" | sudo tee /etc/systemd/zram-generator.conf

# Firewall
sudo pacman -S ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw

# Reflector
sudo pacman -S reflector
sudo systemctl enable reflector.timer

# AUR helper
cd /tmp && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
```

---

## Next Step

Proceed to [06-SNAPPER-SETUP.md](./06-SNAPPER-SETUP.md) for snapshot configuration.
