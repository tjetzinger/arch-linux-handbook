# System Recovery Setup - TODO

Pending tasks to complete the backup and recovery infrastructure.

## Priority: High

### 1. LUKS Header Backup
**Why:** Without this, disk corruption = total data loss.

```bash
# Create backup
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 \
    --header-backup-file ~/Documents/luks-header-$(date +%Y%m%d).bin

# Store in multiple locations:
# - External USB drive
# - Password manager (as attachment)
# - Cloud storage (encrypted)
```

**Reference:** [05-LUKS-KEY-MANAGEMENT.md](./05-LUKS-KEY-MANAGEMENT.md)

---

### 2. Boot Partition Backup Hook
**Why:** /boot is FAT32, not covered by Btrfs snapshots.

```bash
# Create backup script
sudo tee /usr/local/bin/backup-boot << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/tt/Documents/boot-backups"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/boot-$(date +%Y%m%d_%H%M%S).tar.gz" -C / boot
ls -t "$BACKUP_DIR"/boot-*.tar.gz | tail -n +11 | xargs -r rm
EOF
sudo chmod +x /usr/local/bin/backup-boot

# Create pacman hook
sudo tee /etc/pacman.d/hooks/50-boot-backup.hook << 'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Type = Package
Target = linux
Target = linux-lts
Target = systemd
Target = intel-ucode

[Action]
Description = Backing up /boot...
When = PreTransaction
Exec = /usr/local/bin/backup-boot
EOF
```

**Reference:** [10-BOOT-PARTITION-BACKUP.md](./10-BOOT-PARTITION-BACKUP.md)

---

## Priority: Medium

### 3. Initialize Borg Repository
**Why:** Off-disk backup for disaster recovery.

```bash
# On external drive
sudo borg init --encryption=repokey /mnt/external/borg-backup

# Export key (critical!)
sudo borg key export /mnt/external/borg-backup ~/Documents/borg-key.txt

# Store passphrase in password manager
```

**Reference:** [07-BORG-BACKUP-AUTOMATION.md](./07-BORG-BACKUP-AUTOMATION.md)

---

### 4. Setup Borg Automation
**Why:** Automated weekly backups.

```bash
# After initializing repo, enable timer:
sudo systemctl enable --now borg-backup.timer
```

**Reference:** [07-BORG-BACKUP-AUTOMATION.md](./07-BORG-BACKUP-AUTOMATION.md)

---

### 5. Btrfs Maintenance Timer
**Why:** Monthly scrub and balance for filesystem health.

```bash
# Enable built-in scrub timer
sudo systemctl enable --now btrfs-scrub@-.timer

# Or create custom maintenance timer (see docs)
```

**Reference:** [06-BTRFS-MAINTENANCE.md](./06-BTRFS-MAINTENANCE.md)

---

## Priority: Low (Improvements)

### 6. Add @home Subvolume
**Why:** Separate user data from root for easier reinstalls.

**Current:** `/home` is inside `@arch` (snapshotted together)
**Proposed:** Create `@home` subvolume with optional separate snapper config

**Reference:** [09-SUBVOLUME-STRATEGY.md](./09-SUBVOLUME-STRATEGY.md)

---

### 7. Add @log and @cache Subvolumes
**Why:** Exclude logs and cache from snapshots.

- `@log` → `/var/log` (logs shouldn't rollback)
- `@cache` → `/var/cache` (rebuildable data)

**Reference:** [09-SUBVOLUME-STRATEGY.md](./09-SUBVOLUME-STRATEGY.md)

---

### 8. Snapper Config for Documents
**Why:** Version control for important files.

```bash
sudo snapper -c documents create-config /home/tt/Documents
```

**Reference:** [03-SNAPPER-DAILY-USAGE.md](./03-SNAPPER-DAILY-USAGE.md)

---

### 9. Cloud Backup with Rclone
**Why:** Off-site backup for geographic redundancy.

```bash
# Configure remote
rclone config

# Sync borg repo to cloud
rclone sync /mnt/external/borg-backup remote:backups/borg
```

**Reference:** [04-BACKUP-STRATEGY-OVERVIEW.md](./04-BACKUP-STRATEGY-OVERVIEW.md)

---

### 10. Snapshot Boot Entries Script
**Why:** Boot directly into snapshots from systemd-boot menu.

```bash
# Install generator script (see docs)
sudo cp snapshot-boot-entry /usr/local/bin/
sudo chmod +x /usr/local/bin/snapshot-boot-entry

# Create entry before risky changes
sudo snapshot-boot-entry <snapshot-number>
```

**Reference:** [02-SNAPPER-SYSTEMD-BOOT.md](./02-SNAPPER-SYSTEMD-BOOT.md)

---

## Completion Checklist

- [ ] LUKS header backed up to 2+ locations
- [ ] Boot backup hook installed
- [ ] Borg repository initialized
- [ ] Borg key exported and stored safely
- [ ] Borg automation timer enabled
- [ ] Btrfs scrub timer enabled
- [ ] (Optional) @home subvolume created
- [ ] (Optional) @log/@cache subvolumes created
- [ ] (Optional) Documents snapper config
- [ ] (Optional) Rclone cloud backup configured
- [ ] Test recovery procedure from arch-live
- [ ] Test Borg restore

---

## Notes

*Add notes here as you complete tasks or encounter issues.*
