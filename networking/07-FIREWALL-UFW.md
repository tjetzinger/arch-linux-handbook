# UFW Firewall Configuration

## Overview

UFW (Uncomplicated Firewall) provides host-based firewall rules for this system. It integrates with Docker, Waydroid, and Tailscale.

## Current Rules

```bash
sudo ufw status numbered
```

| Rule | Action | From | Purpose |
|------|--------|------|---------|
| 22/tcp | ALLOW | Anywhere | SSH access |
| 53 on waydroid0 | ALLOW | Anywhere | Waydroid DNS |
| 67 on waydroid0 | ALLOW | Anywhere | Waydroid DHCP |
| FWD wlan0 ↔ waydroid0 | ALLOW | - | Waydroid internet access |
| Anywhere | ALLOW | 172.16.0.0/12 | Docker bridge networks |

## Rule Details

### SSH (Port 22)
Standard SSH access for remote administration.

### Waydroid Rules
Required for Android container networking:
- **Port 53**: DNS resolution for Android apps
- **Port 67**: DHCP for container IP assignment
- **Forwarding**: Allows waydroid0 interface to reach internet via wlan0

### Docker Networks
```
172.16.0.0/12 covers:
├── 172.16.0.0/16
├── 172.17.0.0/16  (default bridge)
├── 172.18.0.0/16
├── ...
└── 172.31.0.0/16
```

This allows all Docker containers to communicate with host services without needing per-port rules.

## Commands

### View Rules
```bash
sudo ufw status verbose
sudo ufw status numbered
```

### Add Rules
```bash
# Allow port
sudo ufw allow 8080/tcp

# Allow from specific network
sudo ufw allow from 192.168.1.0/24 to any port 3000

# Allow on specific interface
sudo ufw allow in on docker0 to any port 5432
```

### Delete Rules
```bash
# By number
sudo ufw status numbered
sudo ufw delete 3

# By rule specification
sudo ufw delete allow 8080/tcp
```

### Enable/Disable
```bash
sudo ufw enable
sudo ufw disable
sudo ufw reload
```

## Docker Integration

Docker bypasses UFW by default using iptables DOCKER chain. The 172.16.0.0/12 rule ensures containers can reach host services even when UFW is active.

If you need stricter control:
```bash
# /etc/docker/daemon.json
{
  "iptables": false
}
```

Then manage Docker networking manually via UFW.

## Tailscale Integration

Tailscale traffic (UDP 41641) is handled automatically via the tailscale0 interface. No explicit UFW rules needed for Tailscale mesh connectivity.

For subnet routing (allowing Tailscale peers to reach local services):
```bash
# Already covered by Tailscale's routing, but if needed:
sudo ufw allow in on tailscale0
```

## Logging

```bash
# Enable logging
sudo ufw logging on

# View logs
sudo journalctl -u ufw
sudo grep UFW /var/log/syslog
```

## Default Policies

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed  # Required for Waydroid forwarding
```

## Troubleshooting

### Check if UFW is blocking traffic
```bash
sudo ufw status verbose
sudo iptables -L -n -v | grep -i drop
```

### Reset to defaults
```bash
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
```

### Docker container can't reach host service
```bash
# Check Docker network
docker network inspect bridge | grep Subnet

# Allow that subnet
sudo ufw allow from 172.17.0.0/16
```
