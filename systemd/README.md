# Systemd Services

Documentation for systemd services, timers, and configuration on this Arch Linux system.

## Contents

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | Systemd basics and architecture |
| [02-CORE-SERVICES](./02-CORE-SERVICES.md) | Essential system services |
| [03-NETWORK-SERVICES](./03-NETWORK-SERVICES.md) | Networking daemons |
| [04-POWER-MANAGEMENT](./04-POWER-MANAGEMENT.md) | TLP, cpupower, laptop-mode |
| [05-TIMERS](./05-TIMERS.md) | Maintenance timers |
| [06-SECURITY](./06-SECURITY.md) | UFW firewall |
| [07-DESKTOP-SERVICES](./07-DESKTOP-SERVICES.md) | SDDM and user services |
| [08-HARDWARE](./08-HARDWARE.md) | Hardware-specific services |
| [09-TROUBLESHOOTING](./09-TROUBLESHOOTING.md) | Debugging and common issues |
| [10-PERFORMANCE-TUNING](./10-PERFORMANCE-TUNING.md) | ananicy-cpp, irqbalance, sysctl |

## Service Overview

### Running Services

| Service | Purpose |
|---------|---------|
| NetworkManager | Network connections |
| tailscaled | Tailscale VPN |
| sshd | SSH server |
| docker | Container runtime |
| libvirtd | VM management |
| sddm | Display manager |
| tlp | Power management |
| ananicy-cpp | Process priority management |
| irqbalance | IRQ distribution |
| tor | Anonymous networking |
| logid | Logitech device config |

### Active Timers

| Timer | Schedule | Purpose |
|-------|----------|---------|
| snapper-timeline | Hourly | Create snapshots |
| snapper-cleanup | Hourly | Clean old snapshots |
| reflector | Weekly | Update mirrorlist |
| fstrim | Weekly | SSD TRIM |
| laptop-mode | 150s | Battery polling |

## Quick Reference

```bash
# Service management
systemctl status <service>
systemctl start/stop/restart <service>
systemctl enable/disable <service>

# View logs
journalctl -u <service>
journalctl -u <service> -f      # Follow
journalctl -u <service> --since "1 hour ago"

# List services
systemctl list-units --type=service
systemctl list-units --type=service --state=running
systemctl list-units --type=service --state=failed

# List timers
systemctl list-timers

# Check boot time
systemd-analyze
systemd-analyze blame
```

## Custom Configurations

### Service Overrides

```
/etc/systemd/system/
├── sshd.service.d/
│   └── override.conf       # Wait for Tailscale
└── dnsmasq.service.d/
    └── override.conf       # DNS ordering
```

### Environment Files

```
/etc/default/
├── tailscaled              # Tailscale port/flags
└── cpupower                # CPU governor settings
```

## Related

- [../networking/](../networking/) - Tailscale configuration
- [../docker/](../docker/) - Docker services
- [../virtualization/](../virtualization/) - libvirt services
- [../system-recovery/](../system-recovery/) - Snapper configuration
