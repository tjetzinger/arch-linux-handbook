# 01 - Overview

Systemd architecture and basics for this Arch Linux system.

## What is Systemd

Systemd is the init system and service manager for Linux. It handles:

- **Boot process** - Starting services in correct order
- **Service management** - Start, stop, restart services
- **Logging** - journald for centralized logs
- **Timers** - Cron-like scheduled tasks
- **Targets** - System states (multi-user, graphical, etc.)

## Unit Types

| Type | Extension | Purpose |
|------|-----------|---------|
| Service | `.service` | Daemons and processes |
| Timer | `.timer` | Scheduled tasks |
| Socket | `.socket` | Socket activation |
| Target | `.target` | Grouping/synchronization |
| Mount | `.mount` | Filesystem mounts |
| Path | `.path` | Path-based activation |

## Directory Structure

### System Units

```
/usr/lib/systemd/system/     # Package-provided units
/etc/systemd/system/         # Admin overrides (highest priority)
/run/systemd/system/         # Runtime units
```

### User Units

```
/usr/lib/systemd/user/       # Package-provided
~/.config/systemd/user/      # User-defined
```

## Current System State

### Boot Target

```bash
systemctl get-default
# graphical.target
```

### Boot Time

```bash
systemd-analyze
# Startup finished in 4.5s (firmware) + 1.2s (loader) + 2.1s (kernel) + 5.3s (userspace)
```

### Boot Blame

```bash
systemd-analyze blame | head -10
```

## Service States

| State | Meaning |
|-------|---------|
| active (running) | Service is running |
| active (exited) | One-shot service completed |
| inactive (dead) | Service stopped |
| failed | Service crashed or failed to start |
| enabled | Starts automatically at boot |
| disabled | Does not start at boot |

## Common Commands

### Service Management

```bash
# Start/stop/restart
sudo systemctl start <service>
sudo systemctl stop <service>
sudo systemctl restart <service>
sudo systemctl reload <service>    # Reload config without restart

# Enable/disable at boot
sudo systemctl enable <service>
sudo systemctl disable <service>

# Enable and start
sudo systemctl enable --now <service>

# Status
systemctl status <service>
systemctl is-active <service>
systemctl is-enabled <service>
```

### Viewing Units

```bash
# List all services
systemctl list-units --type=service

# List running services
systemctl list-units --type=service --state=running

# List failed services
systemctl --failed

# List enabled services
systemctl list-unit-files --state=enabled

# Show unit file
systemctl cat <service>

# Show dependencies
systemctl list-dependencies <service>
```

### Timer Management

```bash
# List timers
systemctl list-timers

# Run timer immediately
sudo systemctl start <timer-name>.service
```

## Unit File Structure

### Basic Service

```ini
[Unit]
Description=My Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/myservice
Restart=on-failure
User=myuser

[Install]
WantedBy=multi-user.target
```

### Basic Timer

```ini
[Unit]
Description=My Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

## Overriding Units

### Drop-in Directory

```bash
# Create override
sudo systemctl edit <service>

# Creates /etc/systemd/system/<service>.d/override.conf
```

### Full Override

```bash
# Copy and modify entire unit
sudo systemctl edit --full <service>

# Creates /etc/systemd/system/<service>.service
```

### Reload After Changes

```bash
sudo systemctl daemon-reload
```

## This System's Overrides

### SSH Service

**File:** `/etc/systemd/system/sshd.service.d/override.conf`

```ini
[Unit]
After=tailscaled.service

[Service]
ExecStartPre=/bin/sleep 15
```

Purpose: Ensures Tailscale is running before SSH starts.

### Dnsmasq Service

**File:** `/etc/systemd/system/dnsmasq.service.d/override.conf`

```ini
Before=systemd-resolved.service
```

Purpose: DNS ordering for libvirt networks.

## Targets

### Common Targets

| Target | Purpose |
|--------|---------|
| multi-user.target | Non-graphical multi-user |
| graphical.target | GUI with display manager |
| rescue.target | Single-user rescue mode |
| emergency.target | Emergency shell |

### Change Target

```bash
# Switch to rescue mode
sudo systemctl isolate rescue.target

# Set default boot target
sudo systemctl set-default graphical.target
```

## Quick Reference

```bash
# Status
systemctl status <service>
systemctl --failed

# Control
sudo systemctl start/stop/restart <service>
sudo systemctl enable/disable <service>

# View
systemctl cat <service>
systemctl list-units --type=service

# Edit
sudo systemctl edit <service>
sudo systemctl daemon-reload

# Boot
systemd-analyze
systemd-analyze blame
```

## Related

- [02-CORE-SERVICES](./02-CORE-SERVICES.md) - Essential services
- [05-TIMERS](./05-TIMERS.md) - Timer configuration
- [09-TROUBLESHOOTING](./09-TROUBLESHOOTING.md) - Debugging
