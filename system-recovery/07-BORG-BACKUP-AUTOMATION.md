# Borg Backup Automation

Automated Borg backups with systemd timers for ThinkPad X1 Carbon.

## Current Configuration

| Component | Value |
|-----------|-------|
| Repository | `/mnt/borg-backup/repo` |
| Drive | SanDisk Extreme 1TB (ext4) |
| Backup script | `/usr/local/bin/borg-backup-system` |
| Timer | Daily with 1h random delay |
| Passphrase | `/root/.borg-passphrase` (root) + GNOME Keyring (user) |

---

## Repository Info

```bash
# Set environment for interactive use
export BORG_REPO="/mnt/borg-backup/repo"
export BORG_PASSCOMMAND="secret-tool lookup borg repo"

# List archives
borg list $BORG_REPO

# Repository stats
borg info $BORG_REPO
```

---

## Backup Script

**File:** `/usr/local/bin/borg-backup-system`

```bash
#!/bin/bash
# Borg backup script (system-level, runs as root)
# Repository: /mnt/borg-backup/repo

set -euo pipefail

REPO="/mnt/borg-backup/repo"
BACKUP_NAME="$(hostname)-$(date +%Y-%m-%d_%H%M%S)"

# Get passphrase from root-only file
export BORG_PASSPHRASE="$(cat /root/.borg-passphrase)"

if [[ -z "$BORG_PASSPHRASE" ]]; then
    echo "Error: Could not read passphrase from /root/.borg-passphrase"
    exit 1
fi

# Check if backup drive is mounted
if ! mountpoint -q /mnt/borg-backup; then
    echo "Error: Backup drive not mounted at /mnt/borg-backup"
    exit 1
fi

echo "Starting backup: $BACKUP_NAME"

# Create backup
borg create \
    --verbose \
    --stats \
    --progress \
    --compression zstd,3 \
    --exclude-caches \
    --exclude '/home/tt/Documents' \
    --exclude '/home/tt/Downloads' \
    --exclude '/home/tt/vm-backups' \
    --exclude '/home/tt/Workspace/containers/open-webui-stack/ollama' \
    --exclude '/home/*/.lmstudio/models' \
    --exclude '/home/*/.local/share/waydroid' \
    --exclude '/home/*/.local/share/Trash' \
    --exclude '/home/*/.vscode/extensions' \
    --exclude '/home/*/.nvm' \
    --exclude '/home/*/.cursor' \
    --exclude '/home/*/.nuget' \
    --exclude '/home/*/.conda' \
    --exclude '/home/*/.cache' \
    --exclude '/home/*/.thumbnails' \
    --exclude '/home/*/.npm' \
    --exclude '/home/*/.cargo/registry' \
    --exclude '/home/*/.rustup' \
    --exclude '/home/*/.local/share/Steam' \
    --exclude '/home/*/.wine' \
    --exclude '/var/cache' \
    --exclude '/var/tmp' \
    --exclude '/var/log/journal' \
    --exclude '*.pyc' \
    --exclude '__pycache__' \
    --exclude 'node_modules' \
    --exclude '.git/objects' \
    "$REPO::$BACKUP_NAME" \
    /home/tt \
    /etc \
    /boot \
    /usr/local \
    /root

echo "Backup complete. Pruning old backups..."

# Prune old backups (keep 7 daily, 4 weekly, 6 monthly)
borg prune \
    --verbose \
    --stats \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    "$REPO"

# Compact repository
borg compact "$REPO"

# Fix ownership for user access
chown -R tt:tt "$REPO"

echo "Backup finished successfully"
```

### What's Backed Up

| Path | Contents |
|------|----------|
| `/home/tt` | User data (excluding large caches) |
| `/etc` | System configuration |
| `/boot` | Kernel, initramfs, bootloader |
| `/usr/local` | Custom scripts and binaries |
| `/root` | Root user data |

### What's Excluded

| Category | Paths |
|----------|-------|
| Large data | Documents, Downloads, vm-backups, Ollama models |
| Dev tools | node_modules, .cargo/registry, .rustup, .nvm |
| Caches | .cache, .thumbnails, /var/cache |
| Apps | waydroid, lmstudio models, Steam, Wine |
| Temp | /var/tmp, .local/share/Trash |

---

## Passphrase Storage

### For Automation (root)

```bash
# Stored in root-only file
sudo cat /root/.borg-passphrase  # View
sudo chmod 600 /root/.borg-passphrase  # Permissions
```

### For Interactive Use (user)

```bash
# Store in GNOME Keyring
secret-tool store --label='Borg Backup Passphrase' borg repo

# Retrieve
secret-tool lookup borg repo
```

---

## Systemd Timer

### Service

**File:** `/etc/systemd/system/borg-backup.service`

```ini
[Unit]
Description=Borg Backup (System)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/borg-backup-system
Nice=19
IOSchedulingClass=idle

[Install]
WantedBy=multi-user.target
```

### Timer

**File:** `/etc/systemd/system/borg-backup.timer`

```ini
[Unit]
Description=Daily Borg Backup

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

### Management

```bash
# Check timer status
systemctl list-timers | grep borg

# Run backup manually
sudo systemctl start borg-backup.service

# View logs
journalctl -u borg-backup.service -f

# Enable/disable timer
sudo systemctl enable borg-backup.timer
sudo systemctl disable borg-backup.timer
```

---

## Backup Drive

### fstab Entry

```bash
# Auto-mounts when accessing /mnt/borg-backup (for docking station use)
UUID=e767669c-10e1-47b8-81d0-10d0cb231dd9  /mnt/borg-backup  ext4  rw,noatime,nofail,x-systemd.automount,x-systemd.device-timeout=5,x-systemd.idle-timeout=0  0 2
```

### Manual Mount

```bash
sudo mount /mnt/borg-backup
```

---

## Restore Operations

### List Archives

```bash
export BORG_REPO="/mnt/borg-backup/repo"
export BORG_PASSCOMMAND="secret-tool lookup borg repo"

# List all archives
borg list $BORG_REPO

# With details
borg list --format '{archive:<40} {time} {size}' $BORG_REPO
```

### List Files in Archive

```bash
# List all files
borg list ::archive-name

# Search for file
borg list ::archive-name | grep "filename"
```

### Extract Files

```bash
# Extract entire archive
cd /restore/location
borg extract $BORG_REPO::archive-name

# Extract specific path
borg extract ::archive-name home/tt/.config

# Dry run (show what would be extracted)
borg extract --dry-run --list ::archive-name path/to/file
```

### Mount Archive (Browse)

```bash
# Mount archive as filesystem
mkdir -p /mnt/borg-mount
borg mount ::archive-name /mnt/borg-mount

# Browse and copy files
ls /mnt/borg-mount
cp /mnt/borg-mount/path/to/file /destination

# Unmount
borg umount /mnt/borg-mount
```

---

## Repository Management

### Check Integrity

```bash
# Quick check
borg check $BORG_REPO

# Thorough check (slower)
borg check --verify-data $BORG_REPO
```

### Export Key (Critical!)

```bash
# Export key for disaster recovery
borg key export $BORG_REPO ~/borg-key-backup.txt

# Paper backup
borg key export --paper $BORG_REPO
```

### Delete Archives

```bash
# Delete specific archive
borg delete ::archive-name

# Compact after deletion
borg compact $BORG_REPO
```

---

## Quick Reference

```bash
# Environment setup
export BORG_REPO="/mnt/borg-backup/repo"
export BORG_PASSCOMMAND="secret-tool lookup borg repo"

# Common commands
borg list $BORG_REPO                    # List archives
borg info $BORG_REPO                    # Repository stats
borg list ::archive-name                # Files in archive
borg extract ::archive-name path/       # Extract path
borg mount ::archive-name /mnt/point    # Browse archive
borg check $BORG_REPO                   # Verify integrity

# Manual backup
sudo systemctl start borg-backup.service

# Timer status
systemctl list-timers | grep borg
```

---

## Related

- [11-BORG-RESTORE-X250.md](./11-BORG-RESTORE-X250.md) - Restore to ThinkPad X250
- [08-DISASTER-RECOVERY-CHECKLIST.md](./08-DISASTER-RECOVERY-CHECKLIST.md) - Recovery scenarios
- [04-BACKUP-STRATEGY-OVERVIEW.md](./04-BACKUP-STRATEGY-OVERVIEW.md) - Backup layers
