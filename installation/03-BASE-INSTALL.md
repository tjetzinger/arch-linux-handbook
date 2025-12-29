# 03 - Base Installation

Install base system, generate fstab, and basic configuration.

## Prerequisites

- Disk partitioned and encrypted (02-DISK-SETUP.md)
- All subvolumes mounted at `/mnt`
- Connected to internet

---

## Step 1: Install Base System

### Essential Packages

```bash
pacstrap -K /mnt \
    base \
    linux \
    linux-lts \
    linux-firmware \
    intel-ucode \
    btrfs-progs \
    networkmanager \
    vim \
    sudo
```

| Package | Purpose |
|---------|---------|
| `base` | Minimal Arch base |
| `linux` | Latest kernel |
| `linux-lts` | LTS kernel (fallback) |
| `linux-firmware` | Firmware blobs |
| `intel-ucode` | CPU microcode (use `amd-ucode` for AMD) |
| `btrfs-progs` | Btrfs tools |
| `networkmanager` | Network management |
| `vim` | Text editor |
| `sudo` | Privilege escalation |

### Additional Recommended Packages

```bash
pacstrap /mnt \
    base-devel \
    git \
    man-db \
    man-pages \
    texinfo \
    bash-completion \
    reflector \
    htop \
    rsync
```

---

## Step 2: Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

### Verify fstab

```bash
cat /mnt/etc/fstab
```

Should show entries like:
```
# /dev/mapper/cryptroot
UUID=<btrfs-uuid>   /              btrfs   rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@arch   0 0
UUID=<btrfs-uuid>   /.snapshots    btrfs   rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@.snapshots   0 0
...
# /dev/nvme0n1p1
UUID=<efi-uuid>     /boot          vfat    rw,relatime,...   0 2
```

### Optional: Add noatime to fstab

If genfstab didn't include `noatime`, add it manually:

```bash
vim /mnt/etc/fstab
# Add noatime to btrfs mount options
```

---

## Step 3: Chroot into New System

```bash
arch-chroot /mnt
```

You are now inside the new system.

---

## Step 4: Set Timezone

```bash
# Link timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# Generate /etc/adjtime
hwclock --systohc
```

---

## Step 5: Set Locale

### Edit locale.gen

```bash
vim /etc/locale.gen
```

Uncomment needed locales:
```
en_US.UTF-8 UTF-8
de_DE.UTF-8 UTF-8
```

### Generate Locales

```bash
locale-gen
```

### Set System Locale

```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

---

## Step 6: Set Console Keymap

```bash
echo "KEYMAP=de-latin1" > /etc/vconsole.conf
```

For US keyboard:
```bash
echo "KEYMAP=us" > /etc/vconsole.conf
```

---

## Step 7: Set Hostname

```bash
echo "archlinux" > /etc/hostname
```

### Configure hosts

```bash
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux
EOF
```

Replace `archlinux` with your chosen hostname.

---

## Step 8: Set Root Password

```bash
passwd
```

Choose a strong password.

---

## Step 9: Create User

```bash
# Create user with wheel group
useradd -m -G wheel -s /bin/bash tt

# Set password
passwd tt
```

### Enable sudo for wheel group

```bash
EDITOR=vim visudo
```

Uncomment this line:
```
%wheel ALL=(ALL:ALL) ALL
```

---

## Step 10: Enable Essential Services

```bash
systemctl enable NetworkManager
systemctl enable fstrim.timer  # SSD TRIM
```

---

## Verify Installation

```bash
# Check locale
locale

# Check hostname
cat /etc/hostname

# Check fstab
cat /etc/fstab

# Check users
cat /etc/passwd | grep tt

# Check services
systemctl list-unit-files --state=enabled
```

---

## Quick Reference

```bash
# Install base
pacstrap -K /mnt base linux linux-lts linux-firmware intel-ucode \
    btrfs-progs networkmanager vim sudo base-devel git

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt

# Timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf

# Hostname
echo "archlinux" > /etc/hostname
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux
EOF

# Users
passwd  # root
useradd -m -G wheel -s /bin/bash tt
passwd tt
EDITOR=vim visudo  # uncomment %wheel

# Services
systemctl enable NetworkManager fstrim.timer
```

---

## Still in Chroot

Stay in chroot for the next step. Proceed to [04-BOOTLOADER.md](./04-BOOTLOADER.md).
