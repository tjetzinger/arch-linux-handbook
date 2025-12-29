# 02 - Docker Setup

Docker installation and configuration on Arch Linux.

## Current Configuration

| Setting | Value |
|---------|-------|
| Version | 29.1.1 |
| Compose | 2.40.3 |
| Storage Driver | overlay2 |
| Cgroup | systemd v2 |
| Root Dir | /var/lib/docker |

## Installation

### Install Docker

```bash
# Install Docker and Compose
sudo pacman -S docker docker-compose

# Enable and start service
sudo systemctl enable --now docker.service

# Add user to docker group
sudo usermod -aG docker $USER

# Re-login or use newgrp
newgrp docker
```

### Verify Installation

```bash
# Check version
docker --version
docker compose version

# Test
docker run hello-world

# Check service
systemctl status docker
```

## Service Configuration

### Systemd Service

```bash
# Check status
systemctl status docker

# Start/Stop
sudo systemctl start docker
sudo systemctl stop docker

# Enable on boot
sudo systemctl enable docker
```

### Socket Activation

Docker uses socket activation by default:

```bash
# Check socket
systemctl status docker.socket

# Docker starts on first use
docker ps  # Triggers socket activation
```

## Daemon Configuration

### Create daemon.json (Optional)

**File:** `/etc/docker/daemon.json`

```json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {"base": "172.17.0.0/16", "size": 24}
  ]
}
```

```bash
# Apply changes
sudo systemctl restart docker
```

### Common Options

```json
{
  "dns": ["9.9.9.9", "1.1.1.1"],
  "insecure-registries": [],
  "live-restore": true,
  "userland-proxy": false
}
```

## User Permissions

### Docker Group

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Verify
groups $USER

# Apply without logout
newgrp docker
```

### Rootless Mode (Alternative)

For running Docker without root:

```bash
# Install dependencies
sudo pacman -S fuse-overlayfs slirp4netns

# Setup rootless
dockerd-rootless-setuptool.sh install
```

## Docker Compose

### Compose V2

Docker Compose V2 is integrated as a Docker plugin:

```bash
# Use as plugin
docker compose up -d

# Old syntax (if installed separately)
docker-compose up -d
```

### Compose File Locations

Standard locations (in order of precedence):
1. `compose.yaml`
2. `compose.yml`
3. `docker-compose.yaml`
4. `docker-compose.yml`

### Environment Variables

```bash
# .env file in same directory
COMPOSE_PROJECT_NAME=myproject
COMPOSE_FILE=docker-compose.yml
```

## Storage

### Check Storage

```bash
# Disk usage
docker system df

# Detailed
docker system df -v

# Storage driver info
docker info | grep -i storage
```

### Storage Location

```bash
# Default location
/var/lib/docker/

# Check current
docker info | grep "Docker Root Dir"
```

### Change Storage Location

**File:** `/etc/docker/daemon.json`

```json
{
  "data-root": "/mnt/docker"
}
```

## Networking

### Default Networks

```bash
# List networks
docker network ls

# Default networks:
# - bridge (default for containers)
# - host (share host network)
# - none (no networking)
```

### Create Custom Network

```bash
# Create network
docker network create proxy

# With specific subnet
docker network create --subnet=172.20.0.0/16 mynet
```

## Logging

### Default Logging

```bash
# View container logs
docker logs <container>
docker logs -f <container>  # Follow
docker logs --tail 100 <container>
```

### Configure Logging

**File:** `/etc/docker/daemon.json`

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### Per-Container Logging

```yaml
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## Proxy Configuration

### For Docker Daemon

**File:** `/etc/systemd/system/docker.service.d/http-proxy.conf`

```ini
[Service]
Environment="HTTP_PROXY=http://proxy:8080"
Environment="HTTPS_PROXY=http://proxy:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### For Containers

```yaml
services:
  app:
    environment:
      - HTTP_PROXY=http://proxy:8080
      - HTTPS_PROXY=http://proxy:8080
```

## Security

### Docker Group Warning

Users in the `docker` group have root-equivalent privileges. Consider:
- Limiting group membership
- Using rootless Docker
- Enabling user namespaces

### User Namespaces

**File:** `/etc/docker/daemon.json`

```json
{
  "userns-remap": "default"
}
```

### AppArmor/SELinux

```bash
# Check security options
docker info | grep -i security
```

## Troubleshooting

### Docker Won't Start

```bash
# Check service status
systemctl status docker

# Check logs
journalctl -xeu docker

# Check socket
ls -la /var/run/docker.sock
```

### Permission Denied

```bash
# Check group membership
groups $USER

# Fix socket permissions
sudo chmod 666 /var/run/docker.sock

# Or add to docker group
sudo usermod -aG docker $USER
```

### Disk Space Issues

```bash
# Check usage
docker system df

# Clean up
docker system prune -a
docker volume prune
docker image prune -a
```

### Network Issues

```bash
# Restart Docker networking
sudo systemctl restart docker

# Check iptables
sudo iptables -L -n | grep -i docker
```

## Quick Reference

```bash
# Installation
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Service
systemctl status docker
sudo systemctl restart docker

# Cleanup
docker system prune -a
docker volume prune

# Info
docker info
docker version
docker system df
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Architecture
- [06-NETWORKING](./06-NETWORKING.md) - Network configuration
- [09-MAINTENANCE](./09-MAINTENANCE.md) - Maintenance tasks
