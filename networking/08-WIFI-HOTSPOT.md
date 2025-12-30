# WiFi Hotspot Configuration

## Overview

Create a WiFi hotspot to share ethernet internet via WiFi using NetworkManager and dnsmasq.

## Prerequisites

Check if your WiFi adapter supports AP (Access Point) mode:

```bash
iw list | grep -A 15 "Supported interface modes"
```

Look for `AP` in the output.

## Quick Setup

```bash
# Create and start hotspot
nmcli device wifi hotspot ifname wlan0 ssid "MyHotspot" password "securepassword"

# Show credentials
nmcli dev wifi show-password

# Stop hotspot
nmcli connection down <hotspot-name>

# Restart hotspot
nmcli connection down <hotspot-name> && nmcli connection up <hotspot-name>
```

## UFW Firewall Rules

The hotspot requires specific firewall rules for DHCP, DNS, and traffic forwarding.

### Required Rules

```bash
# DHCP (IP assignment)
sudo ufw allow in on wlan0 to any port 67 proto udp comment "DHCP hotspot"
sudo ufw allow in on wlan0 to any port 68 proto udp comment "DHCP hotspot"

# DNS (name resolution)
sudo ufw allow in on wlan0 to any port 53 comment "DNS for hotspot"

# Forwarding to ethernet (restrictive - only to ethernet, not local networks)
sudo ufw route allow in on wlan0 out on enp+ comment "Hotspot to ethernet"
```

### NAT Configuration

Add to `/etc/ufw/before.rules` before the `*filter` section:

```
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Masquerade hotspot traffic to ethernet interfaces
-A POSTROUTING -s 10.42.0.0/24 -o enp+ -j MASQUERADE
COMMIT
```

Then reload:
```bash
sudo ufw reload
```

## Tailscale Integration

If Tailscale is configured as an exit node, hotspot traffic gets routed through Tailscale by default. To bypass Tailscale for hotspot clients:

```bash
# Add routing rule to use main table for hotspot traffic
sudo ip rule add from 10.42.0.0/24 lookup main priority 5200
```

### Make Persistent

Add to `/etc/networkd-dispatcher/routable.d/hotspot-bypass` or create a systemd service:

```bash
#!/bin/bash
# /etc/networkd-dispatcher/routable.d/50-hotspot-bypass
ip rule show | grep -q "from 10.42.0.0/24" || \
    ip rule add from 10.42.0.0/24 lookup main priority 5200
```

Make executable:
```bash
sudo chmod +x /etc/networkd-dispatcher/routable.d/50-hotspot-bypass
```

## Network Details

| Setting | Value |
|---------|-------|
| Hotspot subnet | 10.42.0.0/24 |
| Gateway (laptop) | 10.42.0.1 |
| DHCP range | 10.42.0.10 - 10.42.0.254 |
| DNS server | 10.42.0.1 (dnsmasq) |

## Troubleshooting

### Client gets IP but no internet

1. **Check NAT rules:**
   ```bash
   sudo iptables -t nat -L POSTROUTING -n -v | grep 10.42
   ```

2. **Check forwarding:**
   ```bash
   sudo iptables -L FORWARD -n -v | grep wlan0
   ```

3. **Check IP forwarding:**
   ```bash
   cat /proc/sys/net/ipv4/ip_forward  # Should be 1
   ```

### Client can't get IP address

Check if DHCP ports are open:
```bash
sudo ufw status | grep -E "67|68"
```

### DNS not resolving

Check if DNS port is open:
```bash
sudo ufw status | grep 53
```

Test DNS from hotspot interface:
```bash
dig @10.42.0.1 google.com +short
```

### Traffic going to wrong interface

Check routing:
```bash
# See where traffic would go
ip route get 8.8.8.8 from 10.42.0.170

# Check Tailscale routing table
ip route show table 52
```

If traffic goes to `tailscale0`, add the bypass rule:
```bash
sudo ip rule add from 10.42.0.0/24 lookup main priority 5200
```

### Debug with logging

```bash
# Log all hotspot forward traffic
sudo iptables -I FORWARD 1 -s 10.42.0.0/24 -j LOG --log-prefix "HOTSPOT: "

# Watch logs
sudo dmesg -w | grep HOTSPOT

# Remove logging rule when done
sudo iptables -D FORWARD 1
```

## Security Considerations

The `ufw route allow in on wlan0 out on enp+` rule only allows:
- Hotspot → Ethernet (internet)

It blocks hotspot devices from accessing:
- Docker containers (172.x.x.x)
- VMs on virbr0 (192.168.122.x)
- Tailscale network (100.x.x.x)
- Other local subnets

Only share the hotspot password with trusted users.

## Connection Summary

| Step | Description |
|------|-------------|
| 1 | Client connects to WiFi hotspot |
| 2 | dnsmasq assigns IP (10.42.0.x) |
| 3 | DNS queries go to 10.42.0.1 (dnsmasq) |
| 4 | Traffic forwarded: wlan0 → enp+ |
| 5 | NAT: 10.42.0.x masqueraded to ethernet IP |
| 6 | Response comes back, NAT reverses |
