# 05 - Network Integration

Tailscale integration with NetworkManager, Docker, and libvirt.

## NetworkManager Integration

### Current Connections

```bash
nmcli connection show --active
```

| Connection | Type | Device |
|------------|------|--------|
| HomeWifi | wifi | wlan0 |
| tailscale0 | tun | tailscale0 |
| virbr0 | bridge | virbr0 |
| docker0 | bridge | docker0 |

### Tailscale and NetworkManager

Tailscale creates and manages `tailscale0` automatically. NetworkManager sees it but doesn't manage it.

```bash
# View Tailscale connection
nmcli connection show tailscale0

# Tailscale manages its own interface
# Don't modify via NetworkManager
```

### WiFi Connection DNS

NetworkManager can set per-connection DNS:

```bash
# View current DNS settings
nmcli connection show "HomeWifi" | grep dns

# Set custom DNS (optional)
nmcli connection modify "HomeWifi" ipv4.dns "192.168.178.1"
nmcli connection modify "HomeWifi" ipv4.dns-search "router.local"
```

### Disable NetworkManager DNS Management

If you want systemd-resolved to fully manage DNS:

```bash
# /etc/NetworkManager/conf.d/dns.conf
[main]
dns=systemd-resolved
```

## Docker Integration

### Current Docker Networks

```bash
docker network ls
```

| Network | Subnet | Interface |
|---------|--------|-----------|
| bridge | 172.17.0.0/16 | docker0 |
| br-xxxx | 172.18-22.0.0/16 | br-xxxx |

### Docker and Tailscale

Docker containers can access Tailscale network through the host.

#### Host Network Mode

```yaml
# docker-compose.yml
services:
  app:
    network_mode: host
    # Container uses host's Tailscale connection
```

#### Exposing Container via Tailscale

```bash
# Container on port 8080
# Accessible at x1:8080 from tailnet
docker run -p 8080:80 nginx

# From another Tailscale device:
curl http://x1.example.com:8080
```

### Tailscale in Container (Alternative)

Run Tailscale inside a container:

```yaml
# docker-compose.yml
services:
  tailscale:
    image: tailscale/tailscale
    container_name: tailscale
    hostname: docker-ts
    environment:
      - TS_AUTHKEY=tskey-xxx
      - TS_STATE_DIR=/var/lib/tailscale
    volumes:
      - ./tailscale-state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - NET_RAW
    restart: unless-stopped

  app:
    network_mode: service:tailscale
    # App uses Tailscale container's network
```

### Docker DNS Resolution

Containers can resolve Tailscale hostnames if using host DNS:

```yaml
services:
  app:
    dns:
      - 127.0.0.53  # systemd-resolved stub
    # Or use host network for full resolution
```

## libvirt/KVM Integration

### Current Configuration

| Network | Subnet | Interface |
|---------|--------|-----------|
| default | 192.168.122.0/24 | virbr0 |

### VMs Accessing Tailscale Network

**Option 1: Host NAT (Default)**

VMs use host's network stack, including Tailscale:

```bash
# VM can access Tailscale IPs through host NAT
# From VM:
ping 100.x.x.x  # Works through host
```

**Option 2: Bridge Mode**

VM gets its own IP on the physical network:

```xml
<!-- VM network config -->
<interface type='bridge'>
  <source bridge='br0'/>
</interface>
```

Then install Tailscale in the VM for direct access.

### Advertising VM Network

Currently advertising `192.168.122.0/24`:

```bash
tailscale set --advertise-routes=192.168.122.0/24
```

This allows:
- Access VMs from other Tailscale devices
- VMs accessible by Tailscale IP (192.168.122.x)

### VM with Tailscale Installed

For VMs that need their own Tailscale identity:

```bash
# Inside VM
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
tailscale up
```

## Firewall Integration

### UFW Rules

```bash
# Allow Tailscale interface
sudo ufw allow in on tailscale0

# Allow forwarding (if subnet router)
sudo ufw route allow in on tailscale0 out on wlan0
sudo ufw route allow in on tailscale0 out on virbr0
```

### iptables (Direct)

Tailscale manages its own iptables rules:

```bash
# View Tailscale rules
sudo iptables -L -n | grep -A5 ts-
```

### Netfilter Mode

```bash
# Check current mode
tailscale debug prefs | grep NetfilterMode

# Modes:
# 0 = off
# 1 = nodivert (simpler, less features)
# 2 = on (default, full features)
```

## Network Namespaces

### Tailscale in Network Namespace

For isolated applications:

```bash
# Create namespace
sudo ip netns add isolated

# Run Tailscale in namespace (advanced)
# Requires separate tailscaled instance
```

## Systemd Service Dependencies

Ensure Tailscale starts after network:

```ini
# /etc/systemd/system/tailscaled.service.d/override.conf
[Unit]
After=network-online.target
Wants=network-online.target
```

## Troubleshooting Integration

### Docker Can't Reach Tailscale IPs

```bash
# Check routing
ip route

# Ensure Tailscale is up
tailscale status

# Test from host first
ping 100.x.x.x
```

### VMs Can't Reach Tailscale

```bash
# Check NAT
sudo iptables -t nat -L POSTROUTING -n -v

# Check forwarding
cat /proc/sys/net/ipv4/ip_forward
```

### NetworkManager Conflicts

```bash
# If NM interferes with Tailscale DNS
sudo systemctl restart systemd-resolved
sudo systemctl restart tailscaled
```

## Quick Reference

```bash
# NetworkManager DNS
nmcli connection show "HomeWifi" | grep dns

# Docker networks
docker network ls
docker network inspect bridge

# libvirt networks
virsh net-list
virsh net-info default

# Firewall
sudo ufw status
sudo iptables -L ts-input -n

# Check all interfaces
ip addr show
ip route
```

## Related

- [03-DNS-CONFIGURATION](./03-DNS-CONFIGURATION.md) - DNS details
- [04-SUBNET-ROUTING](./04-SUBNET-ROUTING.md) - Subnet router setup
