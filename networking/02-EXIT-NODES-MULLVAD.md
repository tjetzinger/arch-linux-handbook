# 02 - Exit Nodes and Mullvad Integration

Using Tailscale exit nodes and Mullvad VPN integration.

## What is an Exit Node?

An exit node routes **all your internet traffic** through another device in your tailnet or through Mullvad's VPN servers.

```
Without Exit Node:
  Your Device → Internet

With Exit Node:
  Your Device → Tailscale → Exit Node → Internet
                              ↑
                    (Mullvad or your own device)
```

## Mullvad Integration

Tailscale has native Mullvad integration. Your tailnet includes Mullvad exit nodes if enabled.

### Current Configuration

| Setting | Value |
|---------|-------|
| Exit Node | de-dus-wg-001.mullvad.ts.net |
| Location | Germany (Düsseldorf) |
| Route All Traffic | Yes |
| Allow LAN Access | Yes |

## List Available Exit Nodes

```bash
# List all exit nodes (including Mullvad)
tailscale exit-node list

# Filter by country
tailscale exit-node list | grep -i germany
tailscale exit-node list | grep -i switzerland
```

### Mullvad Node Naming

```
<country>-<city>-wg-<number>.mullvad.ts.net

Examples:
  de-dus-wg-001    Germany, Düsseldorf
  de-fra-wg-002    Germany, Frankfurt
  ch-zrh-wg-001    Switzerland, Zurich
  us-nyc-wg-001    USA, New York
```

## Using Exit Nodes

### Enable Exit Node

```bash
# Use specific Mullvad node
tailscale set --exit-node=de-dus-wg-001.mullvad.ts.net

# Use your own device as exit node (if configured)
tailscale set --exit-node=nas

# Use suggested best node
tailscale set --exit-node-suggest
```

### Disable Exit Node

```bash
tailscale set --exit-node=
```

### Allow LAN Access While Using Exit Node

Without this, you can't access local devices (printer, NAS, etc.):

```bash
tailscale set --exit-node-allow-lan-access
```

**Current setting:** `ExitNodeAllowLANAccess: true`

## Verify Exit Node

### Check Current Exit Node

```bash
tailscale status | head -5
# Shows current exit node in use

tailscale debug prefs | grep ExitNode
```

### Verify IP Address

```bash
# Check your public IP
curl -s ifconfig.me
curl -s ipinfo.io

# Should show Mullvad's IP, not your ISP's
```

### Check for Leaks

```bash
# DNS leak test
resolvectl query whoami.akamai.net

# Should resolve through Mullvad, not your ISP
```

## Traffic Flow with Exit Node

### All Traffic Mode (Current)

```
RouteAll: true

Local Traffic (192.168.178.x):
  Device → wlan0 → Local Network ✓ (LAN access allowed)

Internet Traffic:
  Device → tailscale0 → Mullvad Exit → Internet

Tailnet Traffic:
  Device → tailscale0 → Direct to peer (or via DERP relay)
```

### Split Tunnel Mode

```bash
# Only route Tailscale traffic, not all internet
tailscale set --exit-node=
# Internet goes directly through your ISP
```

## Setting Up Your Own Exit Node

You can use any device in your tailnet as an exit node.

### On the Exit Node Device

```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Advertise as exit node
tailscale set --advertise-exit-node
```

### Approve in Admin Console

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
2. Find the device
3. Enable "Use as exit node"

### Use Your Exit Node

```bash
tailscale set --exit-node=nas
```

## Kill Switch Behavior

When using an exit node with `--exit-node-allow-lan-access=false`:

- **Exit node disconnects:** No internet access (kill switch)
- **Tailscale stops:** No internet access

With `--exit-node-allow-lan-access=true` (current):

- Local network still accessible
- Not a strict kill switch

### Strict Kill Switch

For maximum privacy:

```bash
tailscale set --exit-node=de-dus-wg-001.mullvad.ts.net
tailscale set --exit-node-allow-lan-access=false
```

## Performance Considerations

| Factor | Impact |
|--------|--------|
| Exit node location | Closer = faster |
| Mullvad server load | Check status page |
| Direct vs relayed | Direct connection preferred |

### Check Connection Type

```bash
tailscale status
# Shows "direct" or relay info for each peer
```

## Switching Between Nodes

### Quick Switch Script

```bash
#!/bin/bash
# ~/scripts/mullvad-switch.sh

case "$1" in
    de)
        tailscale set --exit-node=de-dus-wg-001.mullvad.ts.net
        ;;
    ch)
        tailscale set --exit-node=ch-zrh-wg-001.mullvad.ts.net
        ;;
    us)
        tailscale set --exit-node=us-nyc-wg-001.mullvad.ts.net
        ;;
    off)
        tailscale set --exit-node=
        ;;
    *)
        echo "Usage: $0 {de|ch|us|off}"
        tailscale exit-node list | head -20
        ;;
esac

echo "Current IP:"
curl -s ifconfig.me
```

## Quick Reference

```bash
# List exit nodes
tailscale exit-node list

# Use Mullvad exit node
tailscale set --exit-node=de-dus-wg-001.mullvad.ts.net

# Allow local network access
tailscale set --exit-node-allow-lan-access

# Disable exit node
tailscale set --exit-node=

# Check current status
tailscale status
curl -s ifconfig.me
```

## Related

- [01-TAILSCALE-SETUP](./01-TAILSCALE-SETUP.md) - Basic setup
- [03-DNS-CONFIGURATION](./03-DNS-CONFIGURATION.md) - DNS with exit nodes
