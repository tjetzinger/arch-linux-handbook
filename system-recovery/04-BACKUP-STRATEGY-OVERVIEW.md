# System Backup Strategy Overview

Comprehensive guide to the backup and recovery infrastructure on this system.

## Backup Layers

| Layer | Tool | Purpose | Location |
|-------|------|---------|----------|
| **Snapshots** | Snapper + Btrfs | Instant rollback, undo changes | Local (`/.snapshots`) |
| **Local Backup** | Borg / rsync | Full backups to external drive | External drive |
| **Cloud Backup** | rclone | Off-site backup | Cloud storage |

---

## Layer 1: Btrfs Snapshots (Snapper)

**Purpose:** Quick recovery from config errors, bad updates, broken packages.

### Characteristics
- **Speed:** Instant creation, near-instant rollback
- **Space:** Efficient (copy-on-write, only stores changes)
- **Limitation:** Same disk - no protection from disk failure

### What's Protected
| Subvolume | Snapshotted |
|-----------|-------------|
| `@arch` (/) | Yes |
| `@Documents` | No (separate management needed) |
| `@vm` | No |

### Automated Snapshots
- Hourly timeline snapshots
- Pre/post on every pacman operation (snap-pac)

**See:** [03-SNAPPER-DAILY-USAGE.md](./03-SNAPPER-DAILY-USAGE.md)

---

## Layer 2: Local Backups (Borg)

**Purpose:** Protection from disk failure, theft, ransomware.

### Borg Basics

```bash
# Initialize repository (one-time)
borg init --encryption=repokey /path/to/backup/location

# Create backup
borg create /path/to/repo::archive-name /paths/to/backup

# List archives
borg list /path/to/repo

# Restore
borg extract /path/to/repo::archive-name
```

### Recommended Borg Backup Script

```bash
#!/bin/bash
# /usr/local/bin/system-backup

export BORG_REPO="/mnt/external/backups/borg-repo"
export BORG_PASSPHRASE="your-passphrase"  # Or use keyfile

ARCHIVE_NAME="$(hostname)-$(date +%Y-%m-%d_%H%M)"

# Create backup
borg create \
    --verbose \
    --stats \
    --compression lz4 \
    --exclude-caches \
    --exclude '/home/*/.cache/*' \
    --exclude '/home/*/.local/share/Trash/*' \
    --exclude '/var/cache/*' \
    --exclude '/var/tmp/*' \
    ::$ARCHIVE_NAME \
    /etc \
    /home \
    /root \
    /var/lib \
    /usr/local

# Prune old backups
borg prune \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6

# Compact repository
borg compact
```

### What to Backup with Borg

| Include | Exclude |
|---------|---------|
| `/etc` (configs) | `/home/*/.cache` |
| `/home` (user data) | `/var/cache` |
| `/var/lib` (databases, containers) | `/var/tmp` |
| `/usr/local` (custom scripts) | `/.snapshots` |
| `/root` | `/mnt`, `/media` |

---

## Layer 3: Cloud Backup (rclone)

**Purpose:** Off-site protection, geographic redundancy.

### Configure Remote

```bash
# Interactive setup
rclone config

# Common remotes:
# - Google Drive
# - Dropbox
# - Backblaze B2
# - Synology NAS (WebDAV/SFTP)
```

### Sync to Cloud

```bash
# Sync borg repo to cloud
rclone sync /mnt/external/backups/borg-repo remote:backups/borg

# Sync important documents
rclone sync ~/Documents remote:Documents

# With encryption
rclone sync ~/Documents remote:encrypted-docs --crypt-remote
```

### Encrypted Cloud Backup

```bash
# Setup encrypted remote (wraps another remote)
rclone config
# Choose "crypt" type
# Point to existing remote as backend
```

---

## Backup Schedule Recommendation

| Frequency | What | Tool |
|-----------|------|------|
| Continuous | System changes | Snapper (automatic) |
| Daily | Important documents | rclone to cloud |
| Weekly | Full system | Borg to external |
| Monthly | Borg repo | rclone to cloud |

### Systemd Timer Example

```bash
# /etc/systemd/system/weekly-backup.timer
[Unit]
Description=Weekly Borg Backup

[Timer]
OnCalendar=Sun 02:00
Persistent=true

[Install]
WantedBy=timers.target
```

---

## Recovery Scenarios

### Scenario 1: Bad Package Update
**Use:** Snapper
```bash
snapper undochange <pre>..<post>
```

### Scenario 2: Accidentally Deleted File
**Use:** Snapper (if recent) or Borg
```bash
# From snapshot
cp /.snapshots/NUM/snapshot/path/to/file /path/to/file

# From borg
borg extract /repo::archive path/to/file
```

### Scenario 3: System Won't Boot
**Use:** Snapper via arch-live
- See [01-MANUAL-ARCH-LIVE-RECOVERY.md](./01-MANUAL-ARCH-LIVE-RECOVERY.md)

### Scenario 4: Disk Failure
**Use:** Borg restore to new disk
```bash
# On new system, mount borg repo
borg extract /mnt/backup-drive/borg-repo::latest-archive

# Or restore specific paths
borg extract /repo::archive etc/ home/
```

### Scenario 5: Ransomware / Total Loss
**Use:** Cloud backup (rclone)
```bash
rclone copy remote:backups/borg-repo /mnt/new-disk/
borg extract /mnt/new-disk/borg-repo::archive
```

---

## Installed Backup Tools

| Tool | Version | Purpose |
|------|---------|---------|
| `snapper` | 0.13.0 | Btrfs snapshot management |
| `snap-pac` | 3.0.1 | Pacman hook for snapshots |
| `borg` | 1.4.3 | Deduplicated encrypted backups |
| `rsync` | 3.4.1 | File synchronization |
| `rclone` | 1.72.1 | Cloud storage sync |

---

## Testing Backups

**Critical:** Regularly test that backups are restorable.

### Test Snapper Rollback
```bash
# Create test file
touch /tmp/test-snapshot
sudo snapper create -d "Test snapshot"
rm /tmp/test-snapshot
sudo snapper undochange <num>..0
ls /tmp/test-snapshot  # Should exist
```

### Test Borg Restore
```bash
# List contents
borg list /repo::archive

# Extract to temp location
mkdir /tmp/borg-test
cd /tmp/borg-test
borg extract /repo::archive etc/hostname
cat etc/hostname
```

### Test Cloud Backup
```bash
rclone ls remote:backups/ | head -10
rclone copy remote:backups/test-file /tmp/
```

---

## Security Considerations

| Aspect | Recommendation |
|--------|----------------|
| Borg encryption | Use `repokey` or `keyfile` mode |
| Passphrase | Store securely (password manager) |
| Cloud encryption | Use rclone crypt wrapper |
| Backup drive | Encrypt with LUKS |
| Key backup | Store encryption keys separately |

### Backup Your Encryption Keys!

```bash
# Borg key export
borg key export /repo /safe/location/borg-key.txt

# LUKS header backup
cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file /safe/location/luks-header.bin
```

---

## Quick Setup Checklist

- [ ] Snapper configured (already done)
- [ ] snap-pac installed (already done)
- [ ] Boot entry for recovery snapshot
- [ ] Borg repository initialized
- [ ] Borg backup script created
- [ ] Weekly backup timer enabled
- [ ] rclone remote configured
- [ ] Cloud sync schedule set
- [ ] Encryption keys backed up separately
- [ ] Recovery procedures tested
