# 03 - DNS Configuration

systemd-resolved integration with Tailscale MagicDNS.

## Current DNS Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Applications                             │
│                          ↓                                   │
│              /etc/resolv.conf (stub)                        │
│                   127.0.0.53                                │
│                          ↓                                   │
│               systemd-resolved                               │
│    ┌─────────────────────┼─────────────────────┐            │
│    ↓                     ↓                     ↓            │
│ tailscale0           wlan0                 Global           │
│ 100.100.100.100   192.168.178.1          9.9.9.9           │
│ (MagicDNS)        (Router)            (Fallback)        │
│    │                     │                                   │
│    ↓                     ↓                                   │
│ *.example.com     *.router.local                             │
│ Tailnet devices     Local devices                           │
└─────────────────────────────────────────────────────────────┘
```

## systemd-resolved Configuration

### Main Configuration

**File:** `/etc/systemd/resolved.conf`

```ini
[Resolve]
DNS=9.9.9.9
FallbackDNS=1.1.1.1
```

### Check Status

```bash
# Full status
resolvectl status

# Summary
resolvectl statistics
```

### Current DNS Servers

| Interface | DNS Server | Domain |
|-----------|------------|--------|
| tailscale0 | 100.100.100.100 | example.com, ~. |
| wlan0 | 192.168.178.1 | router.local |
| Global | 9.9.9.9 | (fallback) |

## Tailscale MagicDNS

MagicDNS provides automatic DNS for your tailnet.

### How It Works

1. Tailscale sets up DNS on the `tailscale0` interface
2. DNS server: `100.100.100.100` (Tailscale's internal resolver)
3. Search domain: Your tailnet domain (e.g., `example.com`)

### DNS Names for Devices

| Format | Example | Notes |
|--------|---------|-------|
| Short | `nas` | Works within tailnet |
| With custom domain | `nas.example.com` | Custom search domain |
| Full tailnet FQDN | `nas.danio-locrian.ts.net` | Always works |

### Enable/Disable MagicDNS

```bash
# Enable (default)
tailscale set --accept-dns

# Disable
tailscale set --accept-dns=false
```

### Check MagicDNS Status

```bash
tailscale debug prefs | grep CorpDNS
# CorpDNS: true = MagicDNS enabled
```

## Split DNS

systemd-resolved automatically routes queries to the correct DNS server based on the domain.

### Current Split DNS Rules

| Query | Routed To |
|-------|-----------|
| `nas.example.com` | 100.100.100.100 (Tailscale) |
| `nas` | 100.100.100.100 (via search domain) |
| `printer.router.local` | 192.168.178.1 (Router) |
| `google.com` | 100.100.100.100 (default route via Tailscale) |

### Verify Split DNS

```bash
# Query Tailscale device
resolvectl query nas.example.com

# Query local device
resolvectl query router.local

# Query internet
resolvectl query google.com
```

## DNS Flow with Exit Node

When using Mullvad exit node:

```
DNS Query → systemd-resolved → Tailscale (100.100.100.100)
                                    ↓
                             Mullvad Exit Node
                                    ↓
                             Mullvad DNS or
                             Tailscale MagicDNS
```

### DNS Leak Prevention

With exit node + MagicDNS:
- All DNS queries go through Tailscale
- No queries leak to your ISP

Verify:
```bash
# Check DNS being used
resolvectl status tailscale0

# Test DNS resolution path
dig +trace example.com
```

## Custom DNS Configuration

### Add Custom DNS Server

```bash
# Edit resolved.conf
sudo vim /etc/systemd/resolved.conf
```

```ini
[Resolve]
DNS=9.9.9.9 1.1.1.1
FallbackDNS=8.8.8.8
```

```bash
# Restart resolved
sudo systemctl restart systemd-resolved
```

### Per-Interface DNS (via NetworkManager)

```bash
# Set DNS for specific connection
nmcli connection modify "HomeWifi" ipv4.dns "192.168.178.1"
nmcli connection modify "HomeWifi" ipv4.ignore-auto-dns yes
```

## /etc/resolv.conf

### Current Setup (Stub Resolver)

```bash
ls -la /etc/resolv.conf
# Symlink to /run/systemd/resolve/stub-resolv.conf
```

**Content:**
```
nameserver 127.0.0.53
options edns0 trust-ad
search example.com router.local
```

### Alternative Configurations

| Mode | resolv.conf Points To |
|------|----------------------|
| Stub (current) | `/run/systemd/resolve/stub-resolv.conf` |
| Direct | `/run/systemd/resolve/resolv.conf` |
| Static | Manually managed file |

### Verify Setup

```bash
# Check symlink
ls -la /etc/resolv.conf

# Verify mode
resolvectl status | grep "resolv.conf mode"
```

## Troubleshooting DNS

### Test Resolution

```bash
# Using resolvectl (preferred)
resolvectl query example.com

# Using dig
dig example.com

# Using nslookup
nslookup example.com
```

### Flush DNS Cache

```bash
resolvectl flush-caches
resolvectl statistics
```

### Debug DNS Issues

```bash
# Check which interface handles a query
resolvectl query --legend=no nas.example.com

# Verbose query
resolvectl query -t A --legend=no nas.example.com

# Direct query to specific server
dig @100.100.100.100 nas.example.com
```

### Common Issues

| Issue | Solution |
|-------|----------|
| MagicDNS not working | Check `tailscale set --accept-dns` |
| Local DNS not working | Check `resolvectl status wlan0` |
| DNS leaking | Verify exit node and MagicDNS active |
| Slow resolution | Check `resolvectl statistics` |

## Quick Reference

```bash
# Check DNS status
resolvectl status

# Query a name
resolvectl query hostname.example.com

# Flush cache
resolvectl flush-caches

# Check Tailscale DNS
tailscale debug prefs | grep -i dns

# Enable MagicDNS
tailscale set --accept-dns

# Restart resolved
sudo systemctl restart systemd-resolved
```

## Related

- [01-TAILSCALE-SETUP](./01-TAILSCALE-SETUP.md) - Basic setup
- [02-EXIT-NODES-MULLVAD](./02-EXIT-NODES-MULLVAD.md) - Exit node DNS behavior
