# Networking Documentation

Tailscale VPN, DNS configuration, and network integration guides.

## Current Setup Overview

| Component | Configuration |
|-----------|---------------|
| **Tailscale** | Connected to tailnet |
| **Exit Node** | Mullvad (configurable) |
| **DNS** | systemd-resolved + MagicDNS |
| **Local Network** | 192.168.178.0/24 (Router) |
| **Tailnet Domain** | example.com |

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└─────────────────────────┬───────────────────────────────────┘
                          │
              ┌───────────▼───────────┐
              │   Mullvad Exit Node    │
              │   (de-dus-wg-001)      │
              └───────────┬───────────┘
                          │ WireGuard
              ┌───────────▼───────────┐
              │     tailscale0         │
              │   100.x.x.x       │
              └───────────┬───────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                    x1 (This Machine)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   wlan0     │  │   docker0   │  │   virbr0    │          │
│  │192.168.178. │  │ 172.17.0.1  │  │192.168.122.1│          │
│  │     34      │  │             │  │             │          │
│  └──────┬──────┘  └─────────────┘  └─────────────┘          │
└─────────┼───────────────────────────────────────────────────┘
          │
┌─────────▼─────────┐
│    Router       │
│  192.168.178.1     │
│  (Local Gateway)   │
└───────────────────┘
```

## Tailnet Devices

| Device | Tailscale IP | Type | Notes |
|--------|--------------|------|-------|
| laptop | 100.x.x.x | Linux | This machine |
| nas | 100.x.x.x | Linux | NAS server |
| rpi | 100.x.x.x | Linux | Raspberry Pi |
| phone | 100.x.x.x | Android | Phone |
| desktop | 100.x.x.x | macOS | Mac Mini |
| mobile | 100.x.x.x | iOS | iPhone |

## Documentation Index

| Document | Description |
|----------|-------------|
| [01-TAILSCALE-SETUP](./01-TAILSCALE-SETUP.md) | Installation and basic configuration |
| [02-EXIT-NODES-MULLVAD](./02-EXIT-NODES-MULLVAD.md) | Mullvad integration, exit node usage |
| [03-DNS-CONFIGURATION](./03-DNS-CONFIGURATION.md) | systemd-resolved, MagicDNS, split DNS |
| [04-SUBNET-ROUTING](./04-SUBNET-ROUTING.md) | Advertising routes, remote LAN access |
| [05-NETWORK-INTEGRATION](./05-NETWORK-INTEGRATION.md) | Docker, libvirt, NetworkManager |
| [06-TROUBLESHOOTING](./06-TROUBLESHOOTING.md) | Common issues and debugging |
| [07-FIREWALL-UFW](./07-FIREWALL-UFW.md) | UFW rules for Docker, Waydroid, hotspot |
| [08-WIFI-HOTSPOT](./08-WIFI-HOTSPOT.md) | Share ethernet via WiFi hotspot |

## Quick Reference

### Check Status
```bash
tailscale status
tailscale status --json | jq '.Self'
```

### Switch Exit Node
```bash
# List available exit nodes
tailscale exit-node list

# Use specific exit node
tailscale set --exit-node=de-dus-wg-001.mullvad.ts.net

# Disable exit node
tailscale set --exit-node=
```

### DNS Check
```bash
resolvectl status
resolvectl query nas.example.com
```

### Restart Tailscale
```bash
sudo systemctl restart tailscaled
```
