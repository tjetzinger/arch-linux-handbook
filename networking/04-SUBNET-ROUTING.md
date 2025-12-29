# 04 - Subnet Routing

Advertising routes and accessing local networks remotely via Tailscale.

## What is Subnet Routing?

Subnet routing allows Tailscale devices to access non-Tailscale devices on a local network.

```
Without Subnet Router:
  Phone (away) ──✗──► Printer (192.168.178.50)
                      (No Tailscale installed)

With Subnet Router:
  Phone (away) ──► Tailscale ──► Subnet Router ──► Printer
                                  (NAS/Pi/x1)        (local)
```

## Current Advertised Routes

| Route | Purpose |
|-------|---------|
| 192.168.0.0/24 | (Unknown - possibly outdated) |
| 192.168.122.0/24 | libvirt VM network |

### Check Current Routes

```bash
# Your advertised routes
tailscale debug prefs | grep AdvertiseRoutes

# What peers accept
tailscale status --json | jq '.Self.PrimaryRoutes'
```

## Do You Need to Advertise 192.168.178.0/24?

### Scenarios

| Scenario | Need Subnet Router? |
|----------|---------------------|
| Access local devices while at home | No - direct LAN access |
| Access local devices from away (phone, laptop) | **Yes** |
| Access local devices through exit node at home | No - LAN access allowed |
| Access Router web interface from away | **Yes** |

### Your Current Setup

With `ExitNodeAllowLANAccess: true`:
- When at home: Local network accessible directly
- When using Mullvad exit: Local network still accessible
- When away: **Cannot access 192.168.178.x without subnet router**

## Setting Up Subnet Routing

### Option 1: Use x1 as Subnet Router

Good if x1 is often on at home.

```bash
# On x1
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Advertise the route
tailscale set --advertise-routes=192.168.178.0/24,192.168.122.0/24
```

### Option 2: Use NAS/Pi as Subnet Router (Recommended)

Better because it's always on.

```bash
# On NAS or Pi
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Advertise the route
tailscale set --advertise-routes=192.168.178.0/24
```

### Approve Routes in Admin Console

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
2. Find the subnet router device
3. Click on the device
4. Under "Subnets", approve the advertised routes

### Accept Routes on Clients

On devices that want to use subnet routes:

```bash
tailscale set --accept-routes
```

## Verify Subnet Routing

### Check Route Acceptance

```bash
# See accepted routes
ip route | grep tailscale

# Or
tailscale debug prefs | grep RouteAll
```

### Test Connectivity

```bash
# Ping a device on the subnet (from another Tailscale device)
ping 192.168.178.1    # Router
ping 192.168.178.50   # Some local device
```

## Multiple Subnet Routers (HA)

For high availability, advertise the same subnet from multiple devices.

```bash
# On NAS
tailscale set --advertise-routes=192.168.178.0/24

# On Pi (backup)
tailscale set --advertise-routes=192.168.178.0/24
```

Tailscale will use the best available route.

## 4via6 Subnet Routing

For overlapping subnets across different locations.

```bash
# Advertise with site ID
tailscale set --advertise-routes=192.168.178.0/24 --4via6-site=1
```

Access via: `fd7a:115c:a1e0:b1a:0:1:c0a8:b201` (for 192.168.178.1)

## Updating Advertised Routes

### Add Routes

```bash
# Current: 192.168.0.0/24, 192.168.122.0/24
# Add 192.168.178.0/24

tailscale set --advertise-routes=192.168.0.0/24,192.168.122.0/24,192.168.178.0/24
```

### Remove Routes

```bash
# Remove 192.168.0.0/24, keep others
tailscale set --advertise-routes=192.168.122.0/24,192.168.178.0/24
```

### Clear All Routes

```bash
tailscale set --advertise-routes=
```

## Firewall Considerations

The subnet router must allow forwarding:

```bash
# If using UFW
sudo ufw route allow in on tailscale0 out on wlan0

# If using iptables
sudo iptables -A FORWARD -i tailscale0 -o wlan0 -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o tailscale0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

## Recommended Setup for Your Network

### Clean Up Current Routes

```bash
# Remove outdated 192.168.0.0/24, keep only what you use
tailscale set --advertise-routes=192.168.122.0/24
```

### If You Want Remote Home Access

**Option A: From x1 (when on)**
```bash
tailscale set --advertise-routes=192.168.178.0/24,192.168.122.0/24
```

**Option B: From NAS (recommended - always on)**
```bash
# On NAS
tailscale set --advertise-routes=192.168.178.0/24
```

Then approve in admin console.

## Performance Optimization: UDP GRO Forwarding

When acting as a subnet router, enable UDP GRO (Generic Receive Offload) forwarding for better throughput.

### Why It Matters

| Without | With |
|---------|------|
| Each UDP packet processed individually | Multiple UDP packets merged into one |
| Higher CPU usage | Lower CPU usage |
| ~500-800 Mbps typical | ~1-2+ Gbps possible |

### Check Current Status

```bash
# Check if enabled on an interface
ethtool -k enp0s13f0u3u1c2 | grep rx-udp-gro-forwarding
ethtool -k wlan0 | grep rx-udp-gro-forwarding
```

### Enable Temporarily

```bash
sudo ethtool -K <interface> rx-udp-gro-forwarding on
```

### Enable Persistently (NetworkManager)

Create `/etc/NetworkManager/dispatcher.d/50-tailscale-udp-gro`:

```bash
#!/bin/bash
# Enable UDP GRO forwarding for Tailscale performance
# Applies to all network interfaces (Ethernet, WiFi)

if [[ "$2" == "up" ]]; then
    ethtool -K "$1" rx-udp-gro-forwarding on 2>/dev/null || true
fi
```

Make executable:

```bash
sudo chmod +x /etc/NetworkManager/dispatcher.d/50-tailscale-udp-gro
```

This auto-applies whenever any network interface connects.

### Verify

```bash
# Should show no warning about UDP GRO
sudo tailscale up --advertise-routes=192.168.0.0/24
```

## Quick Reference

```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Advertise routes
tailscale set --advertise-routes=192.168.178.0/24

# Accept routes (on clients)
tailscale set --accept-routes

# Check routes
tailscale debug prefs | grep AdvertiseRoutes
ip route | grep tailscale

# Remove routes
tailscale set --advertise-routes=

# Enable UDP GRO forwarding (better throughput)
sudo ethtool -K <interface> rx-udp-gro-forwarding on
```

## Related

- [01-TAILSCALE-SETUP](./01-TAILSCALE-SETUP.md) - Basic setup
- [02-EXIT-NODES-MULLVAD](./02-EXIT-NODES-MULLVAD.md) - Exit nodes vs subnet routers
