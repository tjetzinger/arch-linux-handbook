# System Recovery Documentation

Recovery, backup, and maintenance documentation for Arch Linux with Btrfs + Snapper + systemd-boot.

## System Overview

| Component | Details |
|-----------|---------|
| OS | Arch Linux |
| Filesystem | Btrfs on LUKS2 |
| Bootloader | systemd-boot |
| Snapshots | Snapper + snap-pac |
| Backup Tools | Borg, rclone, rsync |

---

## Documentation Index

### Recovery Procedures

| # | Document | Description |
|---|----------|-------------|
| 01 | [MANUAL-ARCH-LIVE-RECOVERY.md](./01-MANUAL-ARCH-LIVE-RECOVERY.md) | Emergency recovery using arch-live boot |
| 02 | [SNAPPER-SYSTEMD-BOOT.md](./02-SNAPPER-SYSTEMD-BOOT.md) | Boot into snapshots from systemd-boot menu |
| 08 | [DISASTER-RECOVERY-CHECKLIST.md](./08-DISASTER-RECOVERY-CHECKLIST.md) | Step-by-step recovery scenarios |

### Daily Operations

| # | Document | Description |
|---|----------|-------------|
| 03 | [SNAPPER-DAILY-USAGE.md](./03-SNAPPER-DAILY-USAGE.md) | Common snapper commands |
| 06 | [BTRFS-MAINTENANCE.md](./06-BTRFS-MAINTENANCE.md) | Scrub, balance, defrag, health checks |

### Backup Infrastructure

| # | Document | Description |
|---|----------|-------------|
| 04 | [BACKUP-STRATEGY-OVERVIEW.md](./04-BACKUP-STRATEGY-OVERVIEW.md) | Three-layer backup approach |
| 07 | [BORG-BACKUP-AUTOMATION.md](./07-BORG-BACKUP-AUTOMATION.md) | Automated Borg with systemd timers |
| 10 | [BOOT-PARTITION-BACKUP.md](./10-BOOT-PARTITION-BACKUP.md) | /boot backup (not covered by snapshots) |
| 11 | [BORG-RESTORE-X250.md](./11-BORG-RESTORE-X250.md) | Borg restore to ThinkPad X250 via SSH |

### System Architecture

| # | Document | Description |
|---|----------|-------------|
| 05 | [LUKS-KEY-MANAGEMENT.md](./05-LUKS-KEY-MANAGEMENT.md) | Encryption keys, keyslots, header backup |
| 09 | [SUBVOLUME-STRATEGY.md](./09-SUBVOLUME-STRATEGY.md) | Btrfs subvolume planning and management |

---

## Quick Reference

### Before Risky Changes
```bash
sudo snapper create -d "Before <change>"
```

### Undo Last Package Operation
```bash
snapper list | tail -5
sudo snapper undochange <pre>..<post>
```

### Emergency Boot Recovery
1. Select `Arch Linux Live` at boot
2. `cryptsetup open /dev/nvme0n1p2 cryptroot`
3. `mount -o subvolid=5 /dev/mapper/cryptroot /mnt`
4. See [01-MANUAL-ARCH-LIVE-RECOVERY.md](./01-MANUAL-ARCH-LIVE-RECOVERY.md)

### Monthly Maintenance
```bash
sudo btrfs scrub start /
sudo btrfs balance start -musage=50 /
sudo btrfs device stats /
```

---

## Key System Paths

| Path | Purpose |
|------|---------|
| `/.snapshots/` | Snapper snapshots |
| `/boot/loader/entries/` | systemd-boot entries |
| `/etc/snapper/configs/root` | Snapper configuration |
| `/dev/nvme0n1p2` | LUKS encrypted partition |
| `/dev/mapper/cryptroot` | Unlocked LUKS device |

## Key UUIDs

| Component | UUID |
|-----------|------|
| LUKS partition | `dd8c7166-cbef-454c-a046-9a7efc26bb60` |
| Btrfs filesystem | `7baf5627-b3c5-4add-8b0e-fdd3488f00e0` |

---

## Pre-Disaster Checklist

- [ ] LUKS header backup exists
- [ ] Borg repository key exported
- [ ] Borg backup tested (extract works)
- [ ] Arch Live USB prepared
- [ ] Passwords stored in password manager
- [ ] This documentation accessible offline
