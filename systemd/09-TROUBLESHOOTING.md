# 09 - Troubleshooting

Debugging systemd services and common issues.

## Diagnostic Commands

### Service Status

```bash
# Detailed status
systemctl status <service>

# Check if running
systemctl is-active <service>

# Check if enabled
systemctl is-enabled <service>

# Show failed services
systemctl --failed
```

### Boot Analysis

```bash
# Boot time overview
systemd-analyze

# Time per service
systemd-analyze blame

# Critical chain (boot bottleneck)
systemd-analyze critical-chain

# Plot boot graph
systemd-analyze plot > boot.svg
```

### Service Dependencies

```bash
# What does service need
systemctl list-dependencies <service>

# What needs this service
systemctl list-dependencies --reverse <service>
```

## journalctl (Logs)

### Basic Usage

```bash
# All logs
journalctl

# Follow live
journalctl -f

# Current boot
journalctl -b

# Previous boot
journalctl -b -1

# Specific service
journalctl -u <service>
journalctl -u <service> -f    # Follow
```

### Filtering

```bash
# By priority
journalctl -p err              # Errors and above
journalctl -p warning          # Warnings and above
journalctl -p 0..3             # Emergency to error

# By time
journalctl --since "1 hour ago"
journalctl --since "2025-01-01" --until "2025-01-02"
journalctl --since "09:00" --until "10:00"

# By unit type
journalctl -u "*.service"
journalctl -u "docker*"

# Kernel messages
journalctl -k

# By executable
journalctl _COMM=sshd
journalctl _EXE=/usr/bin/nginx
```

### Output Formats

```bash
# Short (default)
journalctl

# Verbose
journalctl -o verbose

# JSON
journalctl -o json-pretty

# Cat (message only)
journalctl -o cat
```

### Disk Usage

```bash
# Check usage
journalctl --disk-usage

# Clean old logs
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=100M
```

## Common Issues

### Service Won't Start

```bash
# Check status
systemctl status <service>

# Check logs
journalctl -u <service> -n 50

# Check config
systemctl cat <service>

# Try manual start
sudo systemctl start <service>

# Verify dependencies
systemctl list-dependencies <service>
```

### Service Keeps Restarting

```bash
# Check restart settings
systemctl show <service> | grep Restart

# View recent restarts
journalctl -u <service> --since "10 minutes ago"

# Check exit code
systemctl show <service> | grep ExecMainStatus
```

### Service Fails at Boot

```bash
# Check boot logs
journalctl -b -u <service>

# Check ordering
systemctl list-dependencies <service>

# Try after full boot
sudo systemctl start <service>
```

### Permission Denied

```bash
# Check user/group
systemctl show <service> | grep -E "User=|Group="

# Check file permissions
ls -la /path/to/file

# Check SELinux/AppArmor (if applicable)
```

### Port Already in Use

```bash
# Find what's using port
ss -tlnp | grep :8080
lsof -i :8080

# Kill process or stop conflicting service
```

## Debugging Techniques

### Test Service Manually

```bash
# Get ExecStart command
systemctl show <service> -p ExecStart

# Run manually as same user
sudo -u <user> /path/to/command
```

### Increase Verbosity

```bash
# Add to service override
sudo systemctl edit <service>

[Service]
Environment="DEBUG=1"
Environment="LOG_LEVEL=debug"
```

### Check Environment

```bash
# Show environment
systemctl show <service> -p Environment

# Show all properties
systemctl show <service>
```

### Unit File Validation

```bash
# Check for errors
systemd-analyze verify <service>
```

## Specific Service Issues

### Docker Not Starting

```bash
journalctl -u docker
# Check storage driver
docker info
# Check disk space
df -h /var/lib/docker
```

### NetworkManager Issues

```bash
journalctl -u NetworkManager
nmcli general status
nmcli connection show
```

### Tailscale Connection Issues

```bash
journalctl -u tailscaled
tailscale status
tailscale netcheck
```

### Audio Not Working

```bash
# Check PipeWire
systemctl --user status pipewire wireplumber

# Check devices
wpctl status

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### SSH Connection Refused

```bash
# Check service
systemctl status sshd

# Check port
ss -tlnp | grep :22

# Check firewall
sudo ufw status

# Check config
sudo sshd -t
```

## Recovery

### Emergency Mode

If system won't boot normally:

```bash
# At boot, add to kernel command line:
systemd.unit=emergency.target

# Or
systemd.unit=rescue.target
```

### Reset Failed State

```bash
# Reset single service
sudo systemctl reset-failed <service>

# Reset all
sudo systemctl reset-failed
```

### Mask/Unmask Services

```bash
# Prevent service from starting
sudo systemctl mask <service>

# Allow service again
sudo systemctl unmask <service>
```

### Reload Daemon

After editing unit files:
```bash
sudo systemctl daemon-reload
```

## Quick Reference

```bash
# Status
systemctl status <service>
systemctl --failed

# Logs
journalctl -u <service>
journalctl -u <service> -f
journalctl -b -p err

# Boot
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Debug
systemctl show <service>
systemctl cat <service>
systemctl list-dependencies <service>

# Fix
sudo systemctl restart <service>
sudo systemctl reset-failed
sudo systemctl daemon-reload
```

## Log Locations

| Log Type | Command/Location |
|----------|-----------------|
| All logs | `journalctl` |
| Kernel | `journalctl -k` |
| Service | `journalctl -u <service>` |
| User session | `journalctl --user` |
| Boot | `journalctl -b` |
| Auth | `journalctl _COMM=sshd` |

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Systemd basics
- [02-CORE-SERVICES](./02-CORE-SERVICES.md) - journald configuration
- [../system-recovery/](../system-recovery/) - System recovery procedures
