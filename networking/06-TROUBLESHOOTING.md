# 06 - Troubleshooting

Common issues and debugging for Tailscale and network configuration.

## Quick Diagnostics

```bash
# All-in-one status check
tailscale status
tailscale netcheck
resolvectl status | head -30
```

## Connection Issues

### Tailscale Not Connecting

**Symptoms:** `tailscale status` shows offline or "Stopped"

```bash
# Check service status
systemctl status tailscaled

# Restart service
sudo systemctl restart tailscaled

# Check logs
journalctl -u tailscaled -f

# Re-authenticate if needed
tailscale logout
tailscale up
```

### Peer Not Reachable

**Symptoms:** Can't ping or connect to another Tailscale device

```bash
# Check if peer is online
tailscale status | grep <peer-name>

# Ping via Tailscale
tailscale ping <peer-name>

# Check connection type (direct vs relayed)
tailscale status --json | jq '.Peer[] | select(.HostName=="nas") | {HostName, CurAddr, Relay}'
```

### Relayed Connection (Slow)

**Symptoms:** Connection works but is slow (going through DERP relay)

```bash
# Check for relay
tailscale status
# Look for "relay" or absence of "direct"

# Run network check
tailscale netcheck

# Possible causes:
# - Firewall blocking UDP
# - NAT issues
# - One peer offline

# Try reconnecting
tailscale down
tailscale up
```

### Firewall Blocking

```bash
# Check UFW
sudo ufw status verbose

# Allow Tailscale (if needed)
sudo ufw allow 41641/udp  # Tailscale port

# Check iptables
sudo iptables -L -n | grep -i drop
```

## DNS Issues

### MagicDNS Not Resolving

**Symptoms:** Can't resolve `nas.example.com`

```bash
# Check MagicDNS is enabled
tailscale debug prefs | grep CorpDNS

# Enable if needed
tailscale set --accept-dns

# Check systemd-resolved
resolvectl status tailscale0

# Direct query to Tailscale DNS
dig @100.x.x.x nas.example.com

# Flush DNS cache
resolvectl flush-caches
```

### Local DNS Not Working

**Symptoms:** Can't resolve `router.local` or local devices

```bash
# Check wlan0 DNS
resolvectl status wlan0

# Query directly
dig @192.168.178.1 router.local

# Check /etc/resolv.conf
cat /etc/resolv.conf
# Should point to 127.0.0.53
```

### DNS Leaking

**Symptoms:** DNS queries going to ISP instead of Tailscale/Mullvad

```bash
# Check DNS path
resolvectl query whoami.akamai.net

# Verify exit node DNS
curl -s https://dnsleaktest.com/

# Ensure using Tailscale DNS
resolvectl status | grep -A5 tailscale0
```

### Fix DNS After Exit Node Change

```bash
# Restart resolved
sudo systemctl restart systemd-resolved

# Or flush and restart Tailscale
resolvectl flush-caches
sudo systemctl restart tailscaled
```

## Exit Node Issues

### Exit Node Not Working

**Symptoms:** Internet not working or IP doesn't change

```bash
# Check exit node status
tailscale status | head -5

# Verify exit node is set
tailscale debug prefs | grep ExitNode

# Check your public IP
curl -s ifconfig.me

# Try different exit node
tailscale set --exit-node=de-fra-wg-001.mullvad.ts.net
```

### Local Network Not Accessible with Exit Node

```bash
# Enable LAN access
tailscale set --exit-node-allow-lan-access

# Verify
tailscale debug prefs | grep ExitNodeAllowLAN

# Test local access
ping 192.168.178.1
```

### Exit Node Disconnects Frequently

```bash
# Check logs
journalctl -u tailscaled | grep -i exit

# Try a different node
tailscale exit-node list
tailscale set --exit-node=<different-node>

# Check network stability
tailscale netcheck
```

## Subnet Routing Issues

### Can't Access Subnet

**Symptoms:** Can't reach devices on advertised subnet from another Tailscale device

```bash
# On subnet router - check routes are advertised
tailscale debug prefs | grep AdvertiseRoutes

# On subnet router - check routes are approved
tailscale status --json | jq '.Self.PrimaryRoutes'

# On client - check routes are accepted
tailscale set --accept-routes

# Check IP forwarding on subnet router
cat /proc/sys/net/ipv4/ip_forward  # Should be 1
```

### IP Forwarding Not Enabled

```bash
# Enable
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Persist
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

## Service Issues

### Tailscale Won't Start

```bash
# Check service status
systemctl status tailscaled

# Check for conflicts
sudo ss -tulpn | grep 41641

# Clear state and restart
sudo systemctl stop tailscaled
sudo rm /var/lib/tailscale/tailscaled.state
sudo systemctl start tailscaled
tailscale up
```

### High CPU/Memory Usage

```bash
# Check resource usage
top -p $(pgrep tailscaled)

# Restart service
sudo systemctl restart tailscaled

# Check for issues
journalctl -u tailscaled | tail -50
```

## Network Interface Issues

### tailscale0 Missing

```bash
# Check if Tailscale is running
tailscale status

# Restart
sudo systemctl restart tailscaled

# Check interface
ip link show tailscale0
```

### MTU Issues

**Symptoms:** Large packets fail, SSH works but SCP doesn't

```bash
# Check MTU
ip link show tailscale0 | grep mtu

# Tailscale typically uses MTU 1280
# If issues, try lowering application MTU
```

## Debugging Commands

### Comprehensive Network Check

```bash
tailscale netcheck
```

Shows:
- UDP connectivity
- IPv4/IPv6 support
- DERP relay latency
- NAT type

### Detailed Status

```bash
tailscale status --json | jq '.'
```

### Debug Logs

```bash
# Verbose logging
tailscale debug log

# Live logs
journalctl -u tailscaled -f

# Last 100 lines
journalctl -u tailscaled -n 100
```

### Bugreport

```bash
# Generate bug report
tailscale bugreport
```

## Common Fixes Summary

| Issue | Quick Fix |
|-------|-----------|
| Not connecting | `sudo systemctl restart tailscaled` |
| DNS not working | `resolvectl flush-caches` |
| Exit node issues | `tailscale set --exit-node=` then re-set |
| Slow connection | Check `tailscale netcheck` |
| Subnet not working | Check IP forwarding and route approval |
| Auth expired | `tailscale logout && tailscale up` |

## Quick Reference

```bash
# Service
sudo systemctl restart tailscaled
journalctl -u tailscaled -f

# Status
tailscale status
tailscale netcheck
tailscale debug prefs

# DNS
resolvectl status
resolvectl flush-caches
dig @100.x.x.x nas.example.com

# Network
ip addr show tailscale0
ip route | grep tailscale
ping -I tailscale0 100.x.x.x

# Reset
tailscale logout
tailscale up
```
