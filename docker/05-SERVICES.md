# 05 - Services

n8n, Portainer, Watchtower, and other services.

## n8n - Workflow Automation

### Overview

n8n is a workflow automation tool similar to Zapier/Make.

| Setting | Value |
|---------|-------|
| URL | https://n8n.x1.example.com |
| Port | 5678 |
| Image | n8nio/n8n:latest |

### Compose File

**Location:** `~/Workspace/containers/n8n/docker-compose.yml`

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    networks:
      - proxy
    environment:
      - N8N_RUNNERS_ENABLED=true
      - N8N_HOST=n8n.x1.example.com
      - N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.n8n-secure.entrypoints=websecure
      - traefik.http.routers.n8n-secure.rule=Host(`n8n.x1.example.com`)
      - traefik.http.routers.n8n-secure.service=n8n
      - traefik.http.services.n8n.loadbalancer.server.port=5678
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files

volumes:
  n8n_data:

networks:
  proxy:
    external: true
```

### Features

- Visual workflow builder
- 400+ integrations
- Code nodes (JavaScript, Python)
- Webhooks
- Scheduled triggers
- Community nodes

### Data Location

```bash
# Named volume
docker volume inspect n8n_n8n_data

# Local files
~/Workspace/containers/n8n/local-files/
```

### Backup Workflows

```bash
# Export via UI: Settings > Export All Workflows

# Or copy volume
docker run --rm -v n8n_n8n_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/n8n-backup.tar.gz /data
```

## Portainer - Docker Management

### Overview

Web-based Docker management UI.

| Setting | Value |
|---------|-------|
| URL | https://portainer.x1.example.com |
| Port | 9000 |
| Image | portainer/portainer-ce:latest |

### Compose File

**Location:** `~/Workspace/containers/portainer/docker-compose.yml`

```yaml
services:
  portainer:
    image: "portainer/portainer-ce:latest"
    container_name: portainer
    restart: always
    security_opt:
      - "no-new-privileges:true"
    networks:
      - proxy
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./data:/data"
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.portainer-secure.entrypoints=websecure
      - traefik.http.routers.portainer-secure.rule=Host(`portainer.x1.example.com`)
      - traefik.http.routers.portainer-secure.service=portainer
      - traefik.http.services.portainer.loadbalancer.server.port=9000

networks:
  proxy:
    external: true
```

### Features

- Container management
- Image management
- Network management
- Volume management
- Stack deployment
- Log viewing
- Console access

### First-Time Setup

1. Access https://portainer.x1.example.com
2. Create admin user
3. Select "Local" environment

### Data Location

```
~/Workspace/containers/portainer/data/
```

## Watchtower - Auto Updates

### Overview

Automatically updates running containers.

| Setting | Value |
|---------|-------|
| Interval | 300 seconds (5 minutes) |
| Cleanup | Enabled |
| Image | containrrr/watchtower:latest |

### Compose File

**Location:** `~/Workspace/containers/watchtower/docker-compose.yml`

```yaml
services:
  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    environment:
      - DOCKER_API_VERSION=1.45  # Required for Docker 29+
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
    command: --interval 300 --cleanup
```

### Command Options

| Option | Purpose |
|--------|---------|
| --interval 300 | Check every 5 minutes |
| --cleanup | Remove old images |
| --label-enable | Only update labeled containers |
| --no-pull | Don't pull new images |
| --stop-timeout | Timeout for stopping containers |

### Exclude Container from Updates

Add label to container:
```yaml
labels:
  - com.centurylinklabs.watchtower.enable=false
```

### View Update History

```bash
docker logs watchtower
```

### Docker 29 Compatibility

For Docker 29+, set API version:
```yaml
environment:
  - DOCKER_API_VERSION=1.45
```

## Firefox - Browser Container

### Overview

Browser running in a container with GUI.

| Setting | Value |
|---------|-------|
| Ports | 3000, 3001 |
| Image | lscr.io/linuxserver/firefox:latest |

### Compose File

**Location:** `~/Workspace/containers/firefox/docker-compose.yml`

```yaml
services:
  firefox:
    image: lscr.io/linuxserver/firefox:latest
    container_name: firefox
    security_opt:
      - seccomp:unconfined
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    ports:
      - 3000:3000
      - 3001:3001
    shm_size: "1gb"
    restart: unless-stopped
    deploy:
      resources:
        reservations:
          devices:
            - driver: intel
              count: 1
              capabilities: [video]
```

### Access

- HTTP: http://localhost:3000
- HTTPS: https://localhost:3001

### Use Cases

- Isolated browsing
- Testing
- Automation
- Accessing web apps

## nginx - Web Server

### Current Setup

Simple nginx container for static content.

```yaml
services:
  nginx:
    image: nginx:latest
    container_name: nginx
    networks:
      - proxy
    volumes:
      - ./html:/usr/share/nginx/html:ro
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.nginx.entrypoints=websecure
      - traefik.http.routers.nginx.rule=Host(`www.example.com`)

networks:
  proxy:
    external: true
```

## Service Management

### Start Service

```bash
cd ~/Workspace/containers/<service>
docker compose up -d
```

### Stop Service

```bash
docker compose down
```

### View Logs

```bash
docker compose logs -f
# or
docker logs <container> -f
```

### Restart Service

```bash
docker compose restart
```

### Update Service

```bash
docker compose pull
docker compose up -d
```

## Quick Reference

### n8n
```bash
cd ~/Workspace/containers/n8n
docker compose up -d
docker logs n8n -f
```

### Portainer
```bash
cd ~/Workspace/containers/portainer
docker compose up -d
# Access: https://portainer.x1.example.com
```

### Watchtower
```bash
cd ~/Workspace/containers/watchtower
docker compose up -d
docker logs watchtower -f
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Service architecture
- [03-TRAEFIK](./03-TRAEFIK.md) - Routing configuration
- [09-MAINTENANCE](./09-MAINTENANCE.md) - Updates and maintenance
