# Disaster Recovery Checklist

Step-by-step procedures for recovering from various failure scenarios.

---

## Recovery Quick Reference

| Scenario | Severity | Recovery Method |
|----------|----------|-----------------|
| Bad package update | Low | Snapper undochange |
| Broken config | Low | Restore from snapshot |
| Won't boot (software) | Medium | Arch-live + snapshot rollback |
| Won't boot (hardware) | High | Boot repair or reinstall |
| Disk failure | Critical | Borg restore to new disk |
| Total loss | Critical | Full reinstall + Borg restore |

---

## Scenario 1: Bad Package Update

**Symptoms:** Application crashes, missing libraries, system instability after update.

### Recovery Steps

```bash
# 1. Find the update's pre/post snapshots
snapper list | grep "pacman -S"

# 2. Review what changed
snapper status <pre-number>..<post-number>

# 3. Undo the changes
sudo snapper undochange <pre-number>..<post-number>

# 4. Verify system works
systemctl --failed
```

**Time:** 2-5 minutes

---

## Scenario 2: Broken Configuration

**Symptoms:** Service won't start, display issues, network problems.

### Recovery Steps

```bash
# 1. Identify recent snapshots
snapper list | tail -10

# 2. Find the config file in an old snapshot
ls /.snapshots/<number>/snapshot/etc/

# 3. Restore specific file
sudo cp /.snapshots/<number>/snapshot/etc/broken.conf /etc/

# 4. Or diff and manually fix
diff /.snapshots/<number>/snapshot/etc/broken.conf /etc/broken.conf
```

**Time:** 5-10 minutes

---

## Scenario 3: System Won't Boot (Software Issue)

**Symptoms:** Boot hangs, emergency shell, graphical login fails.

### Recovery Steps

```bash
# 1. At systemd-boot menu, select "Arch Linux (Live)"

# 2. Unlock and mount
cryptsetup open /dev/nvme0n1p2 cryptroot
mount -o subvolid=5 /dev/mapper/cryptroot /mnt

# 3. Option A: Quick rollback to known good snapshot
mv /mnt/@arch /mnt/@arch-broken
btrfs subvolume snapshot /mnt/@.snapshots/<good-number>/snapshot /mnt/@arch

# 3. Option B: Use snapper from live
umount /mnt
mount -o subvol=@arch /dev/mapper/cryptroot /mnt
mount -o subvol=@.snapshots /dev/mapper/cryptroot /mnt/.snapshots
snapper --no-dbus --root /mnt undochange <pre>..<post>
umount /mnt/.snapshots

# 4. Unmount and reboot
umount /mnt
reboot
```

**Time:** 10-20 minutes

Full procedure with examples: [01-MANUAL-ARCH-LIVE-RECOVERY](./01-MANUAL-ARCH-LIVE-RECOVERY.md).

---

## Scenario 4: Bootloader Broken

**Symptoms:** "No bootable device", systemd-boot menu missing.

### Recovery Steps

```bash
# 1. Boot from Arch ISO USB

# 2. Unlock and mount system
cryptsetup open /dev/nvme0n1p2 cryptroot
mount -o subvol=@arch /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot

# 3. Chroot into system
arch-chroot /mnt

# 4. Reinstall systemd-boot
bootctl install

# 5. Verify entries exist
ls /boot/loader/entries/

# 6. Regenerate initramfs (if needed)
mkinitcpio -P

# 7. Exit and reboot
exit
umount -R /mnt
reboot
```

**Time:** 15-30 minutes

---

## Scenario 5: Disk Failure (New Disk Available)

**Symptoms:** Disk errors, SMART warnings, complete disk failure.

### Prerequisites
- New disk installed
- Borg backup accessible (external drive or remote)
- Arch ISO for booting

### Recovery Steps

Borg holds **data and configs only** (`/home/tt`, `/etc`, `/boot`, `/usr/local`, `/root`), not `/usr` or the package database. So the order is: fresh base system first, then restore from Borg. Full step-by-step: [11-BORG-RESTORE-X250](./11-BORG-RESTORE-X250.md) (written for the X250 over SSH; on the X1 the disk is `/dev/nvme0n1` and the repo is local).

```bash
# 1. Boot the Arch ISO, partition, LUKS, Btrfs
#    p1: 512M EFI (vfat), p2: LUKS2 -> Btrfs with
#    @arch @.snapshots @Documents @vm @swap @arch-live
#    (see 11-BORG-RESTORE-X250 steps 3-6)

# 2. Install a fresh base system
pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs borg
genfstab -U /mnt >> /mnt/etc/fstab

# 3. Mount the backup drive (repo is the repo/ folder on it)
mkdir /borg && mount /dev/sdX1 /borg
export BORG_REPO=/borg/repo
borg list                      # archives are named <hostname>-YYYY-MM-DD_HHMMSS

# 4. Restore home, root's files (package lists) and configs
cd /mnt
borg extract ::<archive> home/tt root/pkglist-native.txt root/pkglist-foreign.txt
borg extract ::<archive> etc --exclude etc/fstab   # keep the new fstab
chown -R 1000:1000 /mnt/home/tt

# 5. Reinstall packages from the saved lists (in the chroot)
arch-chroot /mnt
pacman -S --needed - < /root/pkglist-native.txt
# AUR packages: install an AUR helper as user tt, then
#   paru -S --needed - < /root/pkglist-foreign.txt

# 6. Point boot config at the new disk
blkid                                   # new LUKS / Btrfs UUIDs
vim /boot/loader/entries/*.conf         # rd.luks.name=<new LUKS UUID>
vim /etc/crypttab                       # if used
# The LUKS keyfile is read from a separate device (rd.luks.key=...:UUID=<keyfile device>).
# Add it to the new LUKS volume: cryptsetup luksAddKey /dev/nvme0n1p2 <keyfile>

# 7. Bootloader and initramfs
bootctl install
mkinitcpio -P
exit; umount -R /mnt; reboot
```

Before 2026-10-12 the Borg script did not save package lists; archives older than that have no `root/pkglist-*.txt`.

**Time:** 1-3 hours

---

## Scenario 6: Complete System Reinstall

**When:** Fresh start preferred, or no viable recovery path.

### Recovery Steps

```bash
# 1. Follow standard Arch installation guide
# 2. After base system is working, restore data from Borg:

# Mount Borg repo
mkdir /mnt/borg
mount /dev/sdX1 /mnt/borg

# Extract home directory
export BORG_PASSPHRASE="passphrase"
cd /home
borg extract /mnt/borg/borg-backup::latest home/

# Extract configs selectively
mkdir /tmp/restore
cd /tmp/restore
borg extract /mnt/borg/borg-backup::latest etc/
# Copy specific configs you need
cp etc/specific.conf /etc/

# 3. Reinstall packages from backup package list
# (If you backed up package list)
pacman -S --needed $(cat /path/to/pkglist.txt)
```

**Time:** 2-4 hours

---

## Pre-Disaster Preparation Checklist

### Critical Backups (Verify Monthly)

- [ ] LUKS header backup exists and is accessible
- [ ] LUKS passphrase stored securely (password manager)
- [ ] Borg repository key exported and stored separately
- [ ] Borg passphrase stored securely
- [ ] Recent Borg backup verified with test restore

### Boot Recovery

- [ ] Arch Live USB drive prepared and accessible
- [ ] arch-live boot entry works
- [ ] Know the LUKS password by memory

### Documentation

- [ ] This recovery documentation accessible offline
- [ ] Hardware specs documented (for replacement)
- [ ] Partition layout documented

---

## Recovery Kit (Physical)

Keep these items accessible:

1. **USB Drive** with:
   - Arch Linux ISO (bootable)
   - LUKS header backup
   - Borg repository key
   - This documentation (PDF)

2. **Password Manager Access** with:
   - LUKS passphrase
   - Borg passphrase
   - Cloud storage credentials (for remote backups)

3. **Written Backup** (secure location):
   - LUKS passphrase
   - Disk layout summary
   - Recovery server access (if applicable)

---

## Post-Recovery Verification

After any recovery:

```bash
# 1. Check for failed services
systemctl --failed

# 2. Verify disk health
sudo btrfs device stats /
sudo smartctl -a /dev/nvme0n1

# 3. Create fresh snapshot
sudo snapper create -d "Post-recovery verified working"

# 4. Run backup
sudo borg-backup

# 5. Update recovery documentation if procedures changed
```

---

## Emergency Contacts

Document your resources:

| Resource | Contact/Location |
|----------|------------------|
| Borg backup | `/mnt/borg-backup/repo` (external USB drive, automounted) |
| Cloud backup | Not set up (no rclone remote configured) |
| LUKS header | USB + cloud |
| Recovery USB | Physical location |
| This documentation | `~/Workspace/arch-linux-guides/system-recovery/`, public copy at https://github.com/youruser/arch-linux-handbook |
