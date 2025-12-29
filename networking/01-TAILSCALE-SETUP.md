# 01 - Tailscale Setup

Installation and basic configuration of Tailscale on Arch Linux.

## Installation

```bash
# Install from official repos
sudo pacman -S tailscale

# Enable and start the daemon
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
```

## Authentication

### Initial Login

```bash
# Authenticate with Tailscale
tailscale up

# Opens browser for authentication
# Or use the URL provided in terminal
```

### Login Options

```bash
# Login with specific options
tailscale up \
    --accept-routes \          # Accept routes from subnet routers
    --accept-dns \             # Use Tailscale DNS (MagicDNS)
    --operator=$USER           # Allow user to manage without sudo
```

### Re-authenticate

```bash
# Force re-authentication
tailscale logout
tailscale up
```

## Current Configuration

### View Status

```bash
# Basic status
tailscale status

# Detailed JSON output
tailscale status --json | jq '.'

# Self info only
tailscale status --json | jq '.Self'
```

### Current Settings

| Setting | Value | Command to Check |
|---------|-------|------------------|
| Exit Node | Mullvad DE | `tailscale status` |
| MagicDNS | Enabled | `tailscale debug prefs \| grep CorpDNS` |
| Accept Routes | Yes | `tailscale debug prefs \| grep RouteAll` |
| LAN Access | Allowed | `tailscale debug prefs \| grep ExitNodeAllowLANAccess` |

### View All Preferences

```bash
tailscale debug prefs
```

## Configuration Commands

### Set Operator (Run Without Sudo)

```bash
# Allow user to run tailscale commands without sudo
sudo tailscale set --operator=$USER
```

### Accept Routes from Subnet Routers

```bash
tailscale set --accept-routes
```

### Enable/Disable Tailscale

```bash
# Disconnect but keep running
tailscale down

# Reconnect
tailscale up

# Full stop
sudo systemctl stop tailscaled
```

## Tailscale IP Addresses

Each device gets:
- **IPv4:** 100.x.x.x (CGNAT range)
- **IPv6:** fd7a:115c:a1e0::xxxx

```bash
# Show your Tailscale IPs
tailscale ip

# IPv4 only
tailscale ip -4

# IPv6 only
tailscale ip -6
```

## MagicDNS

Tailscale provides automatic DNS for all devices in your tailnet.

### DNS Names

| Format | Example |
|--------|---------|
| Short name | `nas` |
| With domain | `nas.example.com` |
| Full FQDN | `nas.danio-locrian.ts.net` |

### Test DNS Resolution

```bash
# Resolve tailnet device
tailscale ping nas

# Or use system resolver
resolvectl query nas.example.com
```

## Service Management

### Systemd Service

```bash
# Status
systemctl status tailscaled

# Logs
journalctl -u tailscaled -f

# Restart
sudo systemctl restart tailscaled
```

### Service File Location

```
/usr/lib/systemd/system/tailscaled.service
```

### State File

```
/var/lib/tailscale/tailscaled.state
```

## Firewall Considerations

Tailscale works with most firewalls. If using UFW:

```bash
# Allow Tailscale interface
sudo ufw allow in on tailscale0
```

## Security Features

### Tailnet Lock (Optional)

Prevents unauthorized devices from joining:

```bash
# Check lock status
tailscale lock status

# Initialize lock (admin only)
tailscale lock init
```

### SSH via Tailscale

```bash
# Enable Tailscale SSH (uses Tailscale auth)
tailscale set --ssh

# Connect to another device
ssh user@device-name
```

## Quick Reference

```bash
# Install
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled

# Login
tailscale up

# Status
tailscale status
tailscale ip

# Configure
tailscale set --operator=$USER
tailscale set --accept-routes
tailscale set --accept-dns

# Debug
tailscale debug prefs
tailscale ping <device>
journalctl -u tailscaled -f
```

## Related

- [02-EXIT-NODES-MULLVAD](./02-EXIT-NODES-MULLVAD.md) - Exit node configuration
- [03-DNS-CONFIGURATION](./03-DNS-CONFIGURATION.md) - DNS setup details
