# 03 - Network Services

Networking daemons and connectivity services.

## Service Summary

| Service | Purpose | Status |
|---------|---------|--------|
| NetworkManager | Network connections | Running |
| tailscaled | Tailscale VPN | Running |
| sshd | SSH server | Running |
| tor | Anonymous network | Running |
| networkd-dispatcher | NM event scripts | Running |

## NetworkManager

Primary network connection manager.

### Status

```bash
systemctl status NetworkManager
nmcli general status
```

### Configuration

**Files:**
- `/etc/NetworkManager/NetworkManager.conf`
- `/etc/NetworkManager/system-connections/`

### Common Commands

```bash
# Show connections
nmcli connection show

# Show devices
nmcli device status

# Connect to WiFi
nmcli device wifi connect "SSID" password "password"

# Show WiFi networks
nmcli device wifi list

# Restart networking
sudo systemctl restart NetworkManager
```

### Integration

- Works with systemd-resolved for DNS
- Tailscale hooks into NM for route management
- libvirt uses NM for bridge networks

## tailscaled

Tailscale VPN daemon.

### Status

```bash
systemctl status tailscaled
tailscale status
```

### Unit File

**Path:** `/usr/lib/systemd/system/tailscaled.service`

```ini
[Service]
EnvironmentFile=/etc/default/tailscaled
ExecStart=/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=${PORT} $FLAGS
```

### Configuration

**File:** `/etc/default/tailscaled`

```bash
PORT="41641"
FLAGS=""
```

### Commands

```bash
# Status
tailscale status

# Network check
tailscale netcheck

# Connect
tailscale up

# Disconnect
tailscale down

# Exit node
tailscale up --exit-node=<node>
```

### Related Documentation

See [../networking/](../networking/) for full Tailscale configuration.

## sshd

OpenSSH server daemon.

### Status

```bash
systemctl status sshd
```

### Override Configuration

**File:** `/etc/systemd/system/sshd.service.d/override.conf`

```ini
[Unit]
After=tailscaled.service

[Service]
ExecStartPre=/bin/sleep 15
```

**Purpose:** Ensures Tailscale is running and has established connection before SSH accepts connections. This allows SSH access via Tailscale IP immediately after boot.

### SSH Configuration

**File:** `/etc/ssh/sshd_config`

Key settings:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

### Commands

```bash
# Restart SSH
sudo systemctl restart sshd

# Check config
sudo sshd -t

# View active connections
ss -tnp | grep :22
```

## tor

Tor anonymous network service.

### Status

```bash
systemctl status tor
```

### Configuration

**File:** `/etc/tor/torrc`

### Unit Features

The tor.service includes extensive hardening:

```ini
[Service]
PrivateTmp=yes
PrivateDevices=yes
ProtectHome=yes
ProtectSystem=full
NoNewPrivileges=yes
```

### Commands

```bash
# Restart Tor
sudo systemctl restart tor

# Check logs
journalctl -u tor
```

## networkd-dispatcher

Runs scripts in response to NetworkManager events.

### Status

```bash
systemctl status networkd-dispatcher
```

### Script Locations

```
/etc/networkd-dispatcher/
├── carrier.d/
├── degraded.d/
├── dormant.d/
├── no-carrier.d/
├── off.d/
├── routable.d/
└── configuring.d/
```

### Use Cases

- Run scripts when network comes up
- Update services on connectivity changes
- Custom network event handling

## wpa_supplicant

WiFi authentication (managed by NetworkManager).

### Status

```bash
systemctl status wpa_supplicant
```

Usually controlled through NetworkManager, not directly.

## Service Startup Order

```
network-pre.target
    │
    ▼
NetworkManager.service ──► systemd-resolved.service
    │
    ▼
tailscaled.service (After=NetworkManager.service)
    │
    ▼
sshd.service (After=tailscaled.service + 15s delay)
    │
    ▼
network-online.target
```

## Firewall Integration

UFW firewall rules for network services:

```bash
sudo ufw status
# 22/tcp ALLOW Anywhere (SSH)
```

See [06-SECURITY](./06-SECURITY.md) for firewall configuration.

## Quick Reference

```bash
# NetworkManager
nmcli connection show
nmcli device status
nmcli device wifi list

# Tailscale
tailscale status
tailscale netcheck
tailscale up/down

# SSH
sudo systemctl restart sshd
ss -tnp | grep :22

# Tor
systemctl status tor
journalctl -u tor

# General
ip addr
ip route
ss -tlnp
```

## Related

- [../networking/](../networking/) - Tailscale documentation
- [06-SECURITY](./06-SECURITY.md) - UFW firewall
- [02-CORE-SERVICES](./02-CORE-SERVICES.md) - systemd-resolved
