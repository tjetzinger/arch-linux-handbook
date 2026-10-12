# 02 - Core Services

Essential system services that form the foundation of the system.

## Service Summary

| Service | Purpose | Status |
|---------|---------|--------|
| systemd-journald | System logging | Running |
| systemd-resolved | DNS resolution | Running |
| systemd-timesyncd | Time synchronization | Running |
| systemd-logind | User sessions | Running |
| systemd-udevd | Device management | Running |
| dbus-broker | Message bus | Running |

## systemd-journald

Centralized logging service.

### Status

```bash
systemctl status systemd-journald
```

### Configuration

**File:** `/etc/systemd/journald.conf.d/size.conf` (drop-in since 2026-10-12; `journald.conf` itself is untouched)

```ini
[Journal]
SystemMaxUse=500M
MaxRetentionSec=1month
```

Storage is persistent because `/var/log/journal/` exists (default `Storage=auto`). Without the drop-in the journal grew to 1.1 GB (default limit: 10% of the filesystem, max 4 GB). Applying `MaxRetentionSec` deletes older logs immediately.

The journal lives inside `@arch`, so every snapper snapshot pins its changing files; keeping it small also keeps snapshots small.

```bash
sudo systemctl restart systemd-journald      # apply, keeps the session
systemd-analyze cat-config systemd/journald.conf | grep -E 'MaxUse|Retention'
journalctl --disk-usage
```

### Common Commands

See [09-TROUBLESHOOTING - journalctl](./09-TROUBLESHOOTING.md#journalctl-logs) for filtering by unit, priority, time and executable, output formats and cleanup.

```bash
journalctl -b -p err        # errors this boot
journalctl -u <service> -f  # follow one service
```

## systemd-resolved

DNS resolution and caching.

### Status

```bash
systemctl status systemd-resolved
resolvectl status
```

### Configuration

**File:** `/etc/systemd/resolved.conf`

Current setup uses Tailscale MagicDNS when connected.

### Commands

```bash
# Check status
resolvectl status

# Query DNS
resolvectl query google.com

# Flush cache
sudo resolvectl flush-caches

# Show statistics
resolvectl statistics
```

### Integration with Tailscale

When Tailscale is active:
- MagicDNS handles `.ts.net` domains
- Split DNS routes queries appropriately
- See [../networking/03-DNS-CONFIGURATION.md](../networking/03-DNS-CONFIGURATION.md)

## systemd-timesyncd

Network time synchronization (NTP client).

### Status

```bash
systemctl status systemd-timesyncd
timedatectl status
```

### Configuration

**File:** `/etc/systemd/timesyncd.conf`

```ini
[Time]
NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org
```

### Commands

```bash
# Check time status
timedatectl

# Show timesync status
timedatectl timesync-status

# Set timezone
sudo timedatectl set-timezone Europe/Vienna

# Enable NTP
sudo timedatectl set-ntp true
```

## systemd-logind

User login and session management.

### Status

```bash
systemctl status systemd-logind
loginctl
```

### Features

- Tracks user sessions
- Manages seat/session permissions
- Handles power keys (lid close, power button)
- Controls multi-seat setups

### Configuration

**File:** `/etc/systemd/logind.conf`

```ini
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
IdleAction=ignore
```

### Commands

```bash
# List sessions
loginctl list-sessions

# Show session info
loginctl show-session <id>

# List users
loginctl list-users

# Lock all sessions
loginctl lock-sessions
```

## systemd-udevd

Device event handling and management.

### Status

```bash
systemctl status systemd-udevd
```

### Features

- Creates device nodes in /dev
- Runs rules when devices are added/removed
- Sets permissions and symlinks

### Commands

```bash
# Monitor events
udevadm monitor

# Get device info
udevadm info /dev/sda

# Trigger rules
sudo udevadm trigger

# Reload rules
sudo udevadm control --reload
```

### Custom Rules Location

```
/etc/udev/rules.d/
```

## dbus-broker

D-Bus message bus (using dbus-broker implementation).

### Status

```bash
systemctl status dbus-broker
```

### Purpose

- Inter-process communication
- Desktop notifications
- Service activation
- Hardware events

### System vs User Bus

```bash
# System bus
/run/dbus/system_bus_socket

# User bus
/run/user/1000/bus
```

## polkit

Authorization framework.

### Status

```bash
systemctl status polkit
```

### Purpose

- Controls privileged operations
- Manages sudo-like authorization
- Handles GUI authentication prompts

### Rules Location

```
/etc/polkit-1/rules.d/
/usr/share/polkit-1/rules.d/
```

## Service Dependencies

```
multi-user.target
├── dbus-broker.service
├── systemd-journald.service
├── systemd-logind.service
├── systemd-resolved.service
├── systemd-timesyncd.service
└── systemd-udevd.service
```

## Quick Reference

```bash
# Journald
journalctl -u <service>
journalctl -f
journalctl --disk-usage

# Resolved
resolvectl status
resolvectl flush-caches

# Timesyncd
timedatectl status
timedatectl timesync-status

# Logind
loginctl list-sessions

# Udev
udevadm monitor
udevadm info /dev/<device>
```

## Related

- [03-NETWORK-SERVICES](./03-NETWORK-SERVICES.md) - Network daemons
- [09-TROUBLESHOOTING](./09-TROUBLESHOOTING.md) - Log analysis
- [../networking/03-DNS-CONFIGURATION.md](../networking/03-DNS-CONFIGURATION.md) - DNS setup
