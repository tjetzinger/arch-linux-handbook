# Snapper Daily Usage Guide

Quick reference for common snapper operations on this system.

## Current Configuration

| Setting | Value |
|---------|-------|
| Config name | `root` |
| Snapshots location | `/.snapshots` |
| Auto pre/post | Yes (snap-pac) |
| Timeline snapshots | Hourly |

---

## Common Commands

### List Snapshots

```bash
# Full list
snapper list

# Compact list
snapper list --columns number,type,date,description

# Last 10 snapshots
snapper list | tail -10
```

### Create Manual Snapshot

```bash
# Simple snapshot
sudo snapper create -d "Description here"

# Snapshot with specific type
sudo snapper create -d "Before major change" --type single

# Pre/post pair (for manual operations)
sudo snapper create -d "Before risky operation" --type pre
# ... do risky things ...
sudo snapper create -d "After risky operation" --type post --pre-number <pre-number>
```

### Compare Snapshots

```bash
# List changed files between two snapshots
snapper status 1570..1575

# Show actual diff of a specific file
snapper diff 1570..1575 /etc/pacman.conf

# Show diff for all changed files
snapper diff 1570..1575
```

### Undo Changes

```bash
# Undo all changes between two snapshots
sudo snapper undochange 1570..1575

# Undo changes to specific files only
sudo snapper undochange 1570..1575 /etc/pacman.conf /etc/fstab

# Preview what would be undone (dry-run)
snapper status 1570..1575
```

### Delete Snapshots

```bash
# Delete single snapshot
sudo snapper delete 1570

# Delete range
sudo snapper delete 1570-1575

# Delete with cleanup (frees space immediately)
sudo snapper delete --sync 1570
```

### Rollback

```bash
# Rollback to a specific snapshot (creates new default)
sudo snapper rollback 1575

# After rollback, reboot
sudo reboot
```

---

## Understanding Snapshot Types

| Type | Created By | Purpose |
|------|-----------|---------|
| `single` | Manual / timeline | General snapshot |
| `pre` | snap-pac / manual | Before a change |
| `post` | snap-pac / manual | After a change (linked to pre) |
| `timeline` | Automatic timer | Hourly/daily automatic |

### Cleanup Algorithms

| Algorithm | Snapshots Affected |
|-----------|-------------------|
| `number` | pre/post pairs, keeps last N |
| `timeline` | timeline snapshots, keeps hourly/daily/monthly |

---

## Snap-pac Automatic Snapshots

Every `pacman` operation automatically creates pre/post snapshots:

```bash
# Example: Installing a package
sudo pacman -S firefox

# Automatically creates:
# - Pre snapshot: "pacman -S firefox"
# - Post snapshot: "firefox" (package name)
```

### View Package Operation History

```bash
# Find all pacman-related snapshots
snapper list | grep pacman

# See what packages changed
snapper status <pre>..<post>
```

### Undo a Package Installation

```bash
# Find the pre/post pair
snapper list | grep "package-name"

# Undo (this effectively uninstalls)
sudo snapper undochange <pre>..<post>

# Alternative: Use pacman to remove
sudo pacman -R package-name
```

---

## Browsing Snapshot Contents

### Direct Access

```bash
# Snapshots are accessible at:
ls /.snapshots/<number>/snapshot/

# Example: View old config file
cat /.snapshots/1575/snapshot/etc/pacman.conf

# Compare with current
diff /.snapshots/1575/snapshot/etc/pacman.conf /etc/pacman.conf
```

### Restore Single File from Snapshot

```bash
# Copy file from snapshot to current system
sudo cp /.snapshots/1575/snapshot/etc/myconfig /etc/myconfig

# Restore with original permissions
sudo cp -a /.snapshots/1575/snapshot/path/to/file /path/to/file
```

---

## Disk Space Management

### Check Snapshot Space Usage

```bash
# Overall btrfs usage
sudo btrfs filesystem usage /

# Space used by snapshots specifically
sudo btrfs filesystem du -s /.snapshots/*/snapshot 2>/dev/null | head -20

# Quick check
df -h /
```

### Free Space by Removing Old Snapshots

```bash
# Remove specific old snapshots
sudo snapper delete 14 741 1341

# Trigger cleanup based on config
sudo snapper cleanup number
sudo snapper cleanup timeline

# Force sync to free space immediately
sudo btrfs filesystem sync /
```

---

## Configuration Reference

### View Current Config

```bash
sudo cat /etc/snapper/configs/root
```

### Key Settings

| Setting | Description |
|---------|-------------|
| `TIMELINE_CREATE` | Enable hourly snapshots |
| `TIMELINE_LIMIT_HOURLY` | Keep last N hourly |
| `TIMELINE_LIMIT_DAILY` | Keep last N daily |
| `TIMELINE_LIMIT_WEEKLY` | Keep last N weekly |
| `TIMELINE_LIMIT_MONTHLY` | Keep last N monthly |
| `NUMBER_LIMIT` | Max pre/post pairs to keep |

### Modify Settings

```bash
sudo snapper -c root set-config "TIMELINE_LIMIT_HOURLY=10"
sudo snapper -c root set-config "NUMBER_LIMIT=20"
```

---

## Workflow Examples

### Before System Update

```bash
# Create named snapshot
sudo snapper create -d "Before system upgrade $(date +%Y-%m-%d)"

# Run update
sudo pacman -Syu

# If problems occur
snapper list | tail -5
sudo snapper undochange <pre>..<post>
```

### Before Installing New Desktop Environment

```bash
# 1. Create snapshot with meaningful name
sudo snapper create -d "Before Plasma install - Hyprland working"

# 2. Note the snapshot number
snapper list | tail -1

# 3. Install Plasma
sudo pacman -S plasma-meta

# 4. If Plasma doesn't work
sudo snapper undochange <your-snapshot>..0
# Note: 0 refers to current state
```

### Experimenting with Configs

```bash
# Save current state
sudo snapper create -d "Working network config"

# Make changes to /etc/...
# Test...

# If broken, restore just that file
sudo cp /.snapshots/<num>/snapshot/etc/myconfig /etc/myconfig

# Or undo all changes
sudo snapper undochange <num>..0
```

---

## Quick Reference Card

```bash
# LIST
snapper list

# CREATE
sudo snapper create -d "description"

# COMPARE
snapper status OLD..NEW
snapper diff OLD..NEW

# UNDO
sudo snapper undochange OLD..NEW

# DELETE
sudo snapper delete NUMBER

# ROLLBACK (full system)
sudo snapper rollback NUMBER && reboot

# VIEW OLD FILE
cat /.snapshots/NUM/snapshot/path/to/file
```
