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

**File:** `/etc/systemd/journald.conf`

```ini
[Journal]
Storage=persistent
SystemMaxUse=500M
MaxRetentionSec=1month
```

### Common Commands

```bash
# View all logs
journalctl

# Follow logs
journalctl -f

# Logs since boot
journalctl -b

# Logs from previous boot
journalctl -b -1

# Logs for service
journalctl -u <service>

# Kernel messages
journalctl -k

# By priority
journalctl -p err    # Errors and above

# Time range
journalctl --since "1 hour ago"
journalctl --since "2025-01-01" --until "2025-01-02"

# Disk usage
journalctl --disk-usage

# Clean old logs
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=100M
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
