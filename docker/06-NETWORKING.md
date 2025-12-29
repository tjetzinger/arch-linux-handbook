# 06 - Networking

Docker network configuration and Tailscale integration.

## Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Host Network                          │
│                                                          │
│  wlan0 (192.168.178.x)    tailscale0 (100.x.x.x)       │
│           │                        │                     │
│           └────────────┬───────────┘                     │
│                        │                                 │
│              Docker Networks                             │
│     ┌──────────────────┼──────────────────┐             │
│     │                  │                  │             │
│  ┌──┴───┐         ┌────┴────┐        ┌────┴────┐       │
│  │bridge│         │  proxy  │        │ others  │       │
│  │(def) │         │172.22.x │        │         │       │
│  └──────┘         └─────────┘        └─────────┘       │
└─────────────────────────────────────────────────────────┘
```

## Current Networks

```bash
docker network ls
```

| Network | Driver | Purpose |
|---------|--------|---------|
| bridge | bridge | Default network |
| proxy | bridge | Traefik routing |
| host | host | Direct host networking |
| none | null | No networking |

## Proxy Network

Main network for Traefik-routed services.

### Create Proxy Network

```bash
docker network create proxy
```

### Network Configuration

```bash
docker network inspect proxy
```

Typical subnet: `172.22.0.0/16`

### Connect Container to Proxy

```yaml
services:
  app:
    networks:
      - proxy

networks:
  proxy:
    external: true
```

## Default Bridge Network

### Properties

- Created automatically
- Containers can communicate by IP
- No DNS resolution by container name
- Not recommended for production

### When to Use

- Quick testing
- Standalone containers
- No inter-container communication needed

## Custom Networks

### Create Network

```bash
# Simple
docker network create mynetwork

# With options
docker network create \
  --driver bridge \
  --subnet 172.30.0.0/16 \
  --gateway 172.30.0.1 \
  mynetwork
```

### In Compose File

```yaml
networks:
  backend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/16

services:
  app:
    networks:
      - backend
```

## Network Types

### Bridge (Default)

```yaml
networks:
  mynet:
    driver: bridge
```

- Isolated network
- Containers communicate by name
- NAT for external access

### Host

```yaml
services:
  app:
    network_mode: host
```

- Container uses host's network stack
- No isolation
- Best performance

### None

```yaml
services:
  app:
    network_mode: none
```

- No networking
- Complete isolation

### Macvlan

```yaml
networks:
  macvlan:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
```

- Container gets IP on physical network
- Appears as separate device

## Container DNS

### Internal DNS

Docker provides DNS for containers on custom networks:

```bash
# Container can reach others by name
ping other-container
```

### Custom DNS

```yaml
services:
  app:
    dns:
      - 9.9.9.9
      - 1.1.1.1
```

### DNS Search Domains

```yaml
services:
  app:
    dns_search:
      - example.com
```

## Port Mapping

### Expose Ports

```yaml
services:
  app:
    ports:
      - "8080:80"           # host:container
      - "443:443"
      - "127.0.0.1:9000:9000"  # localhost only
```

### Port Ranges

```yaml
ports:
  - "8000-8010:8000-8010"
```

### View Port Mappings

```bash
docker port <container>
```

## Tailscale Integration

### Access Containers via Tailscale

Containers are accessible through the host's Tailscale IP.

```bash
# From any Tailscale device
curl http://100.x.x.x:8080
```

### Tailscale + Traefik

Services are accessible via Tailscale using domain names:

```bash
# Works from any Tailscale device
curl https://ai.x1.example.com
```

MagicDNS resolves `x1.example.com` to the host's Tailscale IP.

### Container with Tailscale

For containers needing their own Tailscale identity:

```yaml
services:
  tailscale:
    image: tailscale/tailscale
    container_name: tailscale
    hostname: container-ts
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
```

## Network Troubleshooting

### Check Container Network

```bash
# View network settings
docker inspect <container> | jq '.[0].NetworkSettings'

# List connected networks
docker inspect <container> | jq '.[0].NetworkSettings.Networks'
```

### Test Connectivity

```bash
# From one container to another
docker exec app1 ping app2

# Check DNS resolution
docker exec app1 nslookup app2
```

### View Network

```bash
# List containers on network
docker network inspect proxy | jq '.[0].Containers'
```

### Debug Network Issues

```bash
# Check iptables
sudo iptables -L -n | grep -i docker

# Check routing
docker exec <container> ip route

# Check DNS
docker exec <container> cat /etc/resolv.conf
```

## Network Security

### Isolate Networks

```yaml
networks:
  frontend:
  backend:
    internal: true  # No external access

services:
  web:
    networks:
      - frontend
      - backend

  db:
    networks:
      - backend  # Only accessible from backend
```

### Limit Connections

```yaml
services:
  app:
    networks:
      proxy:
        aliases:
          - myapp
        ipv4_address: 172.22.0.100
```

## Quick Reference

```bash
# List networks
docker network ls

# Create network
docker network create mynet

# Inspect network
docker network inspect proxy

# Connect container
docker network connect proxy <container>

# Disconnect container
docker network disconnect proxy <container>

# Remove network
docker network rm mynet

# Prune unused
docker network prune
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Network topology
- [03-TRAEFIK](./03-TRAEFIK.md) - Proxy routing
- [../networking/](../networking/) - Tailscale documentation
