# Remote Desktop Access (VNC over SSH)

## Overview

Remote desktop access to Hyprland using wayvnc, tunneled via SSH for security.

| Component | Value |
|-----------|-------|
| VNC Server | wayvnc 0.9.1 |
| Bind Address | 127.0.0.1:5900 (localhost only) |
| Security | SSH tunnel (no exposed VNC port) |
| Android Client | MultiVNC |

## Server Setup

### Configuration

**File:** `~/.config/wayvnc/config`
```ini
address=127.0.0.1
port=5900
```

### Start wayvnc

```bash
# Start manually
wayvnc

# Or with explicit address
wayvnc 127.0.0.1 5900

# Check if running
ss -tlnp | grep 5900
```

### Stop wayvnc

```bash
pkill wayvnc
```

## Android Client Setup (MultiVNC)

1. Install **MultiVNC** from [F-Droid](https://f-droid.org/en/packages/com.coboltforge.dontmind.multivnc/) or Google Play

2. Create new connection with these settings:

| Setting | Value |
|---------|-------|
| Use SSH Tunnel | Enabled |
| SSH Host | Your IP or Tailscale IP (100.x.x.x) |
| SSH Port | 22 |
| SSH Username | tt |
| SSH Auth | Password or Private Key |
| VNC Host | localhost |
| VNC Port | 5900 |

## Connection Flow

```
Android Tablet (MultiVNC)
    ↓ SSH tunnel (encrypted, port 22)
Arch Linux
    ↓ localhost forwarding
wayvnc (127.0.0.1:5900)
    ↓
Hyprland desktop (eDP-1: 1920x1200)
```

## Alternative: Manual SSH Tunnel

If using a VNC client without built-in SSH tunneling:

```bash
# On Android (Termux) or another Linux device:
ssh -L 5900:localhost:5900 tt@<host-ip>

# Then connect VNC client to localhost:5900
```

## Troubleshooting

### wayvnc won't start

```bash
# Check if another instance is running
pgrep wayvnc

# Check Wayland display
echo $WAYLAND_DISPLAY

# Run with verbose output
wayvnc -L debug
```

### Connection refused

```bash
# Verify wayvnc is listening
ss -tlnp | grep 5900

# Check SSH is running
systemctl status sshd
```

### Black screen

wayvnc requires an active Hyprland session. Ensure you're logged into the desktop.

## Quick Reference

```bash
# Start VNC server
wayvnc

# Check status
ss -tlnp | grep 5900
pgrep wayvnc

# Stop VNC server
pkill wayvnc
```

## Related

- [06-NETWORKING-HW](../hardware/06-NETWORKING-HW.md) - Network configuration
- [07-FIREWALL-UFW](../networking/07-FIREWALL-UFW.md) - Firewall rules (SSH allowed)
