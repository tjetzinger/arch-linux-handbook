# 04 - Bootloader Setup

Configure mkinitcpio, systemd-boot, and LUKS keyfile for automatic unlock.

## Prerequisites

- Still in chroot from previous step
- Base system installed

---

## Step 1: Configure mkinitcpio

### Edit mkinitcpio.conf

```bash
vim /etc/mkinitcpio.conf
```

### Set MODULES

```bash
MODULES=(btrfs aesni_intel)
```

| Module | Purpose |
|--------|---------|
| `btrfs` | Btrfs filesystem support |
| `aesni_intel` | Hardware AES acceleration |

For AMD CPUs, use:
```bash
MODULES=(btrfs)
```

### Set BINARIES

```bash
BINARIES=(/usr/bin/btrfs)
```

### Set HOOKS (Systemd-based)

```bash
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

**Important:** We use `sd-encrypt` (systemd), NOT `encrypt` (legacy).

| Hook | Purpose |
|------|---------|
| `base` | Essential utilities |
| `systemd` | Systemd init (replaces udev) |
| `autodetect` | Auto-detect needed modules |
| `microcode` | CPU microcode early loading |
| `modconf` | Load modprobe.d configs |
| `kms` | Kernel Mode Setting (early display) |
| `keyboard` | Keyboard support |
| `sd-vconsole` | Console font/keymap (systemd) |
| `block` | Block device support |
| `sd-encrypt` | LUKS unlock (systemd) |
| `filesystems` | Filesystem modules |
| `fsck` | Filesystem check |

### Generate Initramfs

```bash
mkinitcpio -P
```

This generates initramfs for both `linux` and `linux-lts` kernels.

---

## Step 2: Install systemd-boot

```bash
bootctl install
```

This installs the bootloader to `/boot/EFI/systemd/systemd-bootx64.efi`.

---

## Step 3: Configure Loader

### Main loader.conf

```bash
cat > /boot/loader/loader.conf << 'EOF'
default arch.conf
timeout 3
console-mode max
editor no
EOF
```

| Option | Value | Purpose |
|--------|-------|---------|
| `default` | `arch.conf` | Default boot entry |
| `timeout` | `3` | Menu timeout in seconds |
| `console-mode` | `max` | Maximum resolution |
| `editor` | `no` | Disable kernel command line editing (security) |

---

## Step 4: Get UUIDs

```bash
# LUKS partition UUID (for rd.luks.name)
blkid -s UUID -o value /dev/nvme0n1p2
# Example: dd8c7166-cbef-454c-a046-9a7efc26bb60

# EFI partition UUID (for keyfile location)
blkid -s UUID -o value /dev/nvme0n1p1
# Example: CABD-EB33
```

Save these - you'll need them for boot entries.

---

## Step 5: Create Boot Entries

### Organize Kernel Files (Optional but Recommended)

```bash
# Create directory structure
mkdir -p /boot/EFI/arch

# Move kernel files
mv /boot/vmlinuz-linux /boot/EFI/arch/
mv /boot/vmlinuz-linux-lts /boot/EFI/arch/
mv /boot/initramfs-linux.img /boot/EFI/arch/
mv /boot/initramfs-linux-lts.img /boot/EFI/arch/
mv /boot/initramfs-linux-fallback.img /boot/EFI/arch/
mv /boot/initramfs-linux-lts-fallback.img /boot/EFI/arch/
```

### Create pacman hook to maintain structure

```bash
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
```

### Main Entry (arch.conf)

```bash
cat > /boot/loader/entries/arch.conf << 'EOF'
title   Arch Linux
linux   /EFI/arch/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=LUKS_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@arch rw
EOF
```

Replace `LUKS_UUID` with your actual LUKS partition UUID.

**Example with real UUID:**
```bash
cat > /boot/loader/entries/arch.conf << 'EOF'
title   Arch Linux
linux   /EFI/arch/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@arch rw
EOF
```

### LTS Entry (arch-lts.conf)

```bash
cat > /boot/loader/entries/arch-lts.conf << 'EOF'
title   Arch Linux LTS
linux   /EFI/arch/vmlinuz-linux-lts
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux-lts.img
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@arch rw
EOF
```

---

## Step 6: Create LUKS Keyfile (Auto-Unlock)

This allows automatic unlock using a keyfile stored on the EFI partition, with password fallback.

### Generate Keyfile

```bash
dd bs=512 count=8 if=/dev/urandom of=/boot/luks-keyfile.bin
chmod 400 /boot/luks-keyfile.bin
```

### Add Keyfile to LUKS

```bash
cryptsetup luksAddKey /dev/nvme0n1p2 /boot/luks-keyfile.bin
```

Enter your existing LUKS password when prompted.

### Update Boot Entry with Keyfile

```bash
cat > /boot/loader/entries/arch.conf << 'EOF'
title   Arch Linux
linux   /EFI/arch/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot root=/dev/mapper/cryptroot rd.luks.key=dd8c7166-cbef-454c-a046-9a7efc26bb60=/luks-keyfile.bin:UUID=CABD-EB33 rd.luks.options=dd8c7166-cbef-454c-a046-9a7efc26bb60=keyfile-timeout=5s rootflags=subvol=@arch rw
EOF
```

Replace:
- `dd8c7166-cbef-454c-a046-9a7efc26bb60` with your LUKS UUID
- `CABD-EB33` with your EFI partition UUID

**Options explained:**
| Option | Purpose |
|--------|---------|
| `rd.luks.name=UUID=name` | LUKS device to name mapping |
| `rd.luks.key=UUID=/path:UUID` | Keyfile path on partition |
| `rd.luks.options=UUID=keyfile-timeout=5s` | Wait 5s for keyfile, then prompt for password |

### Update LTS Entry Similarly

```bash
cat > /boot/loader/entries/arch-lts.conf << 'EOF'
title   Arch Linux LTS
linux   /EFI/arch/vmlinuz-linux-lts
initrd  /intel-ucode.img
initrd  /EFI/arch/initramfs-linux-lts.img
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot root=/dev/mapper/cryptroot rd.luks.key=dd8c7166-cbef-454c-a046-9a7efc26bb60=/luks-keyfile.bin:UUID=CABD-EB33 rd.luks.options=dd8c7166-cbef-454c-a046-9a7efc26bb60=keyfile-timeout=5s rootflags=subvol=@arch rw
EOF
```

---

## Step 7: Plymouth Boot Splash (Optional)

Plymouth provides a graphical boot splash that hides kernel messages and displays an animated LUKS password prompt.

### Install Plymouth

```bash
yay -S plymouth plymouth-theme-arch-charge
```

### Update mkinitcpio.conf

Add `plymouth` hook after `systemd`:

```bash
HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms sd-vconsole block sd-encrypt filesystems fsck)
```

### Set Theme

```bash
# List available themes
plymouth-set-default-theme -l

# Set arch-charge theme and rebuild initramfs
sudo plymouth-set-default-theme -R arch-charge
```

### Add Kernel Parameters

Add `quiet splash` to your boot entries:

```bash
# Edit each entry in /boot/loader/entries/
# Add to end of options line:
options ... rw quiet splash
```

### Rebuild Initramfs

```bash
sudo mkinitcpio -P
```

### Theme Files

The `arch-charge` theme includes:

| File | Purpose |
|------|---------|
| `lock.png` | Lock icon for LUKS prompt |
| `entry.png` | Password input field |
| `bullet.png` | Password masking (•••) |
| `progress-*.png` | Boot progress animation |

### Preview Without Reboot

```bash
sudo plymouthd --mode=boot && sudo plymouth show-splash && sleep 5 && sudo plymouth quit
```

### Boot Experience

1. Arch logo with charging animation appears
2. Lock icon + password field when LUKS prompts
3. Progress bar after successful unlock
4. Smooth transition to SDDM/login

---

## Step 8: Create Recovery Entry (arch-live)

For booting into recovery environment (will be installed later):

```bash
cat > /boot/loader/entries/arch-live.conf << 'EOF'
title   Arch Linux Live (Recovery)
linux   /EFI/arch-live/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /EFI/arch-live/initramfs-linux.img
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot root=/dev/mapper/cryptroot rd.luks.key=dd8c7166-cbef-454c-a046-9a7efc26bb60=/luks-keyfile.bin:UUID=CABD-EB33 rd.luks.options=dd8c7166-cbef-454c-a046-9a7efc26bb60=keyfile-timeout=5s rootflags=subvol=@arch-live rw
EOF
```

---

## Step 8: Verify Configuration

```bash
# List boot entries
bootctl list

# Check bootloader status
bootctl status

# Verify entries exist
ls -la /boot/loader/entries/

# Check kernel files
ls -la /boot/EFI/arch/
```

---

## First Boot Test

```bash
# Exit chroot
exit

# Unmount all
umount -R /mnt

# Close LUKS
cryptsetup close cryptroot

# Reboot
reboot
```

**Expected behavior:**
1. systemd-boot menu appears
2. Select "Arch Linux"
3. Keyfile is read, system unlocks automatically
4. (Or after 5s, password prompt appears if keyfile fails)
5. System boots to login prompt

---

## Troubleshooting

### Boot Hangs at LUKS
- Wrong UUID in boot entry
- Keyfile not found or wrong path
- Check: `rd.luks.name`, `rd.luks.key` UUIDs match `blkid` output

### Kernel Panic: VFS Unable to Mount Root
- Wrong `rootflags=subvol=` name
- Missing btrfs module in mkinitcpio
- Regenerate: `mkinitcpio -P`

### No Boot Menu
- Bootloader not installed properly
- Reinstall: `bootctl install`

### Keyfile Not Working
- Permissions wrong (should be 400)
- Not added to LUKS: `cryptsetup luksDump /dev/nvme0n1p2` - check keyslots
- EFI UUID wrong in boot entry

---

## Quick Reference

```bash
# mkinitcpio.conf
MODULES=(btrfs aesni_intel)
BINARIES=(/usr/bin/btrfs)
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

# Regenerate
mkinitcpio -P

# Install bootloader
bootctl install

# Keyfile
dd bs=512 count=8 if=/dev/urandom of=/boot/luks-keyfile.bin
chmod 400 /boot/luks-keyfile.bin
cryptsetup luksAddKey /dev/nvme0n1p2 /boot/luks-keyfile.bin

# Boot entry options (all on one line)
options rd.luks.name=LUKS_UUID=cryptroot root=/dev/mapper/cryptroot rd.luks.key=LUKS_UUID=/luks-keyfile.bin:UUID=EFI_UUID rd.luks.options=LUKS_UUID=keyfile-timeout=5s rootflags=subvol=@arch rw
```

---

## Next Step

Proceed to [05-SYSTEM-CONFIG.md](./05-SYSTEM-CONFIG.md) for additional system configuration.
