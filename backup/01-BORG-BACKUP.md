# Borg Backup Configuration

## Overview

Incremental, deduplicated backups using BorgBackup to external SSD.

| Component | Value |
|-----------|-------|
| Repository | `/mnt/borg-backup/repo` |
| Drive | SanDisk Extreme 1TB (ext4) |
| Encryption | repokey-blake2 |
| Compression | zstd level 3 |
| Schedule | Daily at midnight (system service) |

## Backup Scope

### Included
- `~` (configs, workspace, projects)
- `/etc` (full system configuration)
- `/root`

### Excluded
Large/re-downloadable directories:
```
~/Documents
~/Downloads
~/vm-backups
~/Workspace/containers/open-webui-stack/ollama
~/.lmstudio/models
~/.local/share/waydroid
~/.local/share/Trash
~/.vscode/extensions
~/.nvm
~/.cursor
~/.nuget
~/.conda
~/.cache
~/.npm
~/.cargo/registry
~/.rustup
~/.local/share/Steam
~/.wine
node_modules
.git/objects
__pycache__
```

## Files

| File | Purpose |
|------|---------|
| `/usr/local/bin/borg-backup-system` | System backup script (runs as root) |
| `/etc/systemd/system/borg-backup.service` | Systemd service |
| `/etc/systemd/system/borg-backup.timer` | Daily timer |
| `/root/.borg-passphrase` | Passphrase file (mode 600) |

### Legacy (user-level, disabled)
| File | Purpose |
|------|---------|
| `~/.local/bin/borg-backup` | User backup script |
| `~/.config/systemd/user/borg-backup.*` | User service/timer |

## Commands

### Manual Backup
```bash
sudo /usr/local/bin/borg-backup-system
```

### List Archives
```bash
sudo BORG_PASSPHRASE="$(sudo cat /root/.borg-passphrase)" borg list /mnt/borg-backup/repo
```

### View Archive Info
```bash
sudo BORG_PASSPHRASE="$(sudo cat /root/.borg-passphrase)" borg info /mnt/borg-backup/repo::ARCHIVE_NAME
```

### Extract Files
```bash
# Set passphrase
export BORG_PASSPHRASE="$(sudo cat /root/.borg-passphrase)"

# Extract specific file
sudo -E borg extract /mnt/borg-backup/repo::ARCHIVE_NAME home/tt/.config/file

# Extract to different location
cd /tmp && sudo -E borg extract /mnt/borg-backup/repo::ARCHIVE_NAME
```

### Mount Archive (browse as filesystem)
```bash
mkdir /tmp/borg-mount
sudo BORG_PASSPHRASE="$(sudo cat /root/.borg-passphrase)" borg mount /mnt/borg-backup/repo::ARCHIVE_NAME /tmp/borg-mount
# Browse files...
sudo borg umount /tmp/borg-mount
```

### Check Repository Integrity
```bash
sudo BORG_PASSPHRASE="$(sudo cat /root/.borg-passphrase)" borg check /mnt/borg-backup/repo
```

## Retention Policy

| Keep | Count |
|------|-------|
| Daily | 7 |
| Weekly | 4 |
| Monthly | 6 |

## Timer Management

```bash
# Check timer status
sudo systemctl status borg-backup.timer

# View next scheduled run
sudo systemctl list-timers borg-backup.timer

# Run backup now
sudo systemctl start borg-backup.service

# View backup logs
sudo journalctl -u borg-backup.service

# Disable timer
sudo systemctl disable borg-backup.timer
```

## Passphrase

Stored in `/root/.borg-passphrase` (root-only, mode 600).

Also in GNOME Keyring for manual use:
```bash
secret-tool lookup borg-repo /mnt/borg-backup/repo
```

## Key Backup

Export encryption key for disaster recovery:
```bash
sudo BORG_PASSPHRASE="$(sudo cat /root/.borg-passphrase)" borg key export /mnt/borg-backup/repo ~/borg-key-backup.txt
```

Store `borg-key-backup.txt` securely offline (USB, printed, password manager).

## Drive Mount

fstab entry (auto-mounts when connected, doesn't block boot if missing):
```
UUID=<DATA-UUID>  /mnt/borg-backup  ext4  rw,nofail,x-systemd.device-timeout=1  0 2
```

## Migration to Larger Drive

When repository fills up (~800GB):
```bash
# Copy entire repo to new drive
sudo rsync -avP /mnt/borg-backup/repo/ /mnt/new-drive/repo/

# Update fstab with new UUID
sudo blkid /dev/sdX1
```
