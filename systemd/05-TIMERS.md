# 05 - Timers

Systemd timers for scheduled maintenance tasks.

## Active Timers

```bash
systemctl list-timers --all
```

Live on 2026-10-12 (16 timers):

| Timer | Schedule | Purpose | Doc |
|-------|----------|---------|-----|
| snapper-timeline | Hourly | Create Btrfs snapshots | below |
| snapper-cleanup | 10 min after boot, then hourly | Clean old snapshots | below |
| snapper-boot | At boot | Boot snapshot | below |
| snapper-boot-entries | Hourly | systemd-boot entries for snapshots | [02-SNAPPER-SYSTEMD-BOOT](../system-recovery/02-SNAPPER-SYSTEMD-BOOT.md) |
| borg-backup | Daily (±1h) | Borg backup to the external drive | [07-BORG](../system-recovery/07-BORG-BACKUP-AUTOMATION.md) |
| btrfs-scrub@- | Monthly | Scrub `/` | [06-BTRFS](../system-recovery/06-BTRFS-MAINTENANCE.md) |
| btrfs-balance-metadata | 15th, 03:00 | Metadata balance `-musage=50` | [06-BTRFS](../system-recovery/06-BTRFS-MAINTENANCE.md) |
| reflector | 2 min after boot, then weekly | Update pacman mirrors (custom timer) | below |
| flatpak-update | 2 min after boot, then daily | `flatpak update` | [07-DESKTOP-SERVICES](./07-DESKTOP-SERVICES.md#flatpak-services) |
| paccache | Weekly | Prune the pacman cache (`paccache -r`) | - |
| archlinux-keyring-wkd-sync | Weekly | Refresh Arch keyring keys | - |
| fstrim | Weekly | SSD TRIM | - |
| plocate-updatedb | Daily | Update file database | - |
| shadow | Daily | Check password expiry | - |
| systemd-tmpfiles-clean | 15 min after boot, then daily | Clean temp files | - |
| laptop-mode | - | Listed, but the unit is not installed (leftover) | - |

## Snapper Timers

Automated Btrfs snapshot management.

### snapper-timeline.timer

Creates hourly snapshots.

```bash
systemctl status snapper-timeline.timer
```

**Schedule:** `OnCalendar=hourly`

### snapper-cleanup.timer

Cleans old snapshots based on retention policy.

```bash
systemctl status snapper-cleanup.timer
```

**Schedule:** `OnBootSec=10m, OnUnitActiveSec=1h`

> **Known pitfall — silently dead timer:** this timer only has monotonic triggers
> (`OnBootSec`/`OnUnitActiveSec`, no `OnCalendar`). A drop-in override that redefines
> `OnUnitActiveSec` (e.g. to slow it to daily) can leave the unit stuck `active
> (elapsed)` **forever** — it looks healthy in `systemctl status` (enabled, active,
> no failures) but never fires again. `systemctl list-timers` is the tell: a wedged
> timer shows `NEXT: -` / `LAST: -` indefinitely, and
> `systemctl show snapper-cleanup.timer -p NextElapseUSecMonotonic` reads `infinity`.
> Since snapshots keep getting *created* by `snapper-timeline.timer` (a separate,
> working `OnCalendar=hourly` timer) but never *cleaned up*, this silently grows the
> snapshot count for weeks/months, bloating the Btrfs metadata chunk and degrading
> whole-system responsiveness. See
> [system-recovery/06-BTRFS-MAINTENANCE.md](../system-recovery/06-BTRFS-MAINTENANCE.md#metadata-chunk-nearly-full--system-feels-laggy)
> for the full incident and fix. Diagnose and fix:
> ```bash
> systemctl list-timers snapper-cleanup.timer         # NEXT/LAST both "-" = wedged
> systemctl show snapper-cleanup.timer -p NextElapseUSecMonotonic -p LastTriggerUSec
> # Fix: remove the broken drop-in (or correct it to use OnCalendar=, which is
> # wall-clock based and doesn't have this failure mode), then:
> sudo systemctl daemon-reload
> sudo systemctl restart snapper-cleanup.timer
> systemctl list-timers snapper-cleanup.timer          # should now show a real NEXT time
> ```

### snapper-boot.timer

Creates snapshot at boot.

```bash
systemctl status snapper-boot.timer
```

### Configuration

Snapshot retention is configured in `/etc/snapper/configs/root`:

```
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="10"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="10"
TIMELINE_LIMIT_YEARLY="10"
```

### Commands

```bash
# List snapshots
snapper list

# Manual snapshot
sudo snapper create -d "Before update"

# Check timeline service
systemctl status snapper-timeline.service
```

### Related

See [../system-recovery/03-SNAPPER-DAILY-USAGE.md](../system-recovery/03-SNAPPER-DAILY-USAGE.md)

## reflector.timer

Updates pacman mirrorlist - runs 2 minutes after boot and weekly thereafter.

### Status

```bash
systemctl status reflector.timer
systemctl status reflector.service
```

### Custom Timer (Boot Delay)

The default reflector.timer runs at boot before network is ready, causing failures. A custom timer delays startup:

**File:** `/etc/systemd/system/reflector.timer`

```ini
[Unit]
Description=Refresh Pacman mirrorlist with Reflector (delayed)

[Timer]
OnBootSec=2min
OnUnitActiveSec=1w

[Install]
WantedBy=timers.target
```

| Option | Value | Purpose |
|--------|-------|---------|
| `OnBootSec` | `2min` | Wait for network to be ready |
| `OnUnitActiveSec` | `1w` | Refresh weekly thereafter |

### Setup

```bash
# Create custom timer
sudo tee /etc/systemd/system/reflector.timer << 'EOF'
[Unit]
Description=Refresh Pacman mirrorlist with Reflector (delayed)

[Timer]
OnBootSec=2min
OnUnitActiveSec=1w

[Install]
WantedBy=timers.target
EOF

# Enable timer
sudo systemctl daemon-reload
sudo systemctl enable reflector.timer
```

### Configuration

**File:** `/etc/xdg/reflector/reflector.conf`

```
--save /etc/pacman.d/mirrorlist
--country Germany
--protocol https
--latest 5
--sort age
```

### Manual Run

```bash
sudo systemctl start reflector.service
```

### Check Mirrors

```bash
cat /etc/pacman.d/mirrorlist
```

## fstrim.timer

Weekly SSD TRIM for optimal performance.

### Status

```bash
systemctl status fstrim.timer
```

**Schedule:** `OnCalendar=weekly` with ~100min random delay

### Manual Run

```bash
sudo systemctl start fstrim.service

# Or directly
sudo fstrim -av
```

### Why TRIM?

- Informs SSD which blocks are no longer in use
- Maintains SSD performance over time
- Extends SSD lifespan

## plocate-updatedb.timer

Updates the file locate database daily.

### Status

```bash
systemctl status plocate-updatedb.timer
```

**Schedule:** Daily

### Usage

```bash
# Update database
sudo updatedb

# Search files
locate <filename>
```

## systemd-tmpfiles-clean.timer

Cleans temporary files daily.

### Status

```bash
systemctl status systemd-tmpfiles-clean.timer
```

**Schedule:** Daily (15min after boot, then daily)

### Configuration

Rules in `/etc/tmpfiles.d/` and `/usr/lib/tmpfiles.d/`

## Timer Syntax

### OnCalendar Examples

```ini
OnCalendar=hourly            # Every hour
OnCalendar=daily             # Every day at midnight
OnCalendar=weekly            # Every Monday at midnight
OnCalendar=monthly           # First of every month
OnCalendar=*-*-* 02:00:00    # Every day at 2 AM
OnCalendar=Mon *-*-* 00:00:00  # Every Monday
```

### Other Options

```ini
OnBootSec=10m          # 10 minutes after boot
OnUnitActiveSec=1h     # 1 hour after last activation
Persistent=true        # Run if missed while off
RandomizedDelaySec=1h  # Random delay up to 1 hour
```

## Creating Custom Timers

### Timer Unit

**File:** `/etc/systemd/system/mybackup.timer`

```ini
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

### Service Unit

**File:** `/etc/systemd/system/mybackup.service`

```ini
[Unit]
Description=Backup service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

### Enable Timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now mybackup.timer
```

## Quick Reference

```bash
# List timers
systemctl list-timers
systemctl list-timers --all

# Check specific timer
systemctl status <name>.timer

# Run timer's service now
sudo systemctl start <name>.service

# Enable/disable timer
sudo systemctl enable/disable <name>.timer

# View timer config
systemctl cat <name>.timer

# Test calendar expression
systemd-analyze calendar "daily"
systemd-analyze calendar "*-*-* 02:00:00"
```

## Related

- [../system-recovery/03-SNAPPER-DAILY-USAGE.md](../system-recovery/03-SNAPPER-DAILY-USAGE.md) - Snapper usage
- [01-OVERVIEW](./01-OVERVIEW.md) - Unit file syntax
- [04-POWER-MANAGEMENT](./04-POWER-MANAGEMENT.md) - TLP power management
