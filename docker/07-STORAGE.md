# 07 - Storage

Docker volumes, bind mounts, and data persistence.

## Storage Types

| Type | Use Case | Persistence |
|------|----------|-------------|
| Volumes | Databases, app data | Managed by Docker |
| Bind Mounts | Config files, development | Host filesystem |
| tmpfs | Temporary data | Memory only |

## Current Volumes

```bash
docker volume ls
```

| Volume | Service | Purpose |
|--------|---------|---------|
| n8n_n8n_data | n8n | Workflow data |
| (anonymous) | Various | Temporary data |

## Named Volumes

### Create Volume

```bash
docker volume create mydata
```

### Use in Compose

```yaml
services:
  app:
    volumes:
      - mydata:/app/data

volumes:
  mydata:
```

### Inspect Volume

```bash
docker volume inspect mydata
```

### Volume Location

```
/var/lib/docker/volumes/<name>/_data/
```

## Bind Mounts

### Use in Compose

```yaml
services:
  app:
    volumes:
      - ./config:/app/config:ro      # Read-only
      - ./data:/app/data             # Read-write
      - /etc/localtime:/etc/localtime:ro
```

### Path Types

| Syntax | Type |
|--------|------|
| `./relative` | Relative to compose file |
| `/absolute` | Absolute path |
| `volume_name` | Named volume |

## Current Data Locations

### Traefik

```
~/Workspace/containers/traefik/
├── data/
│   ├── traefik.yml       # Static config
│   ├── acme.json         # Certificates
│   └── configurations/   # Dynamic config
```

### Portainer

```
~/Workspace/containers/portainer/
└── data/                 # Portainer database
```

### Open WebUI Stack

```
~/Workspace/containers/open-webui-stack/
├── ollama/               # LLM models
│   └── models/
├── open-webui/           # WebUI data
│   ├── webui.db
│   └── uploads/
├── db/                   # PostgreSQL data
└── config.yml            # LiteLLM config
```

### n8n

```
# Named volume
docker volume inspect n8n_n8n_data

# Local files
~/Workspace/containers/n8n/local-files/
```

## Backup Strategies

### Backup Named Volume

```bash
# Create backup
docker run --rm \
  -v n8n_n8n_data:/data:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/n8n-data.tar.gz -C /data .

# Restore
docker run --rm \
  -v n8n_n8n_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/n8n-data.tar.gz -C /data
```

### Backup Bind Mounts

```bash
# Simple copy
cp -r ~/Workspace/containers/open-webui-stack/open-webui ~/backup/

# With tar
tar czf backup.tar.gz ~/Workspace/containers/
```

### Database Backup

```bash
# PostgreSQL
docker exec postgres pg_dump -U llmproxy litellm > backup.sql

# Restore
cat backup.sql | docker exec -i postgres psql -U llmproxy litellm
```

## Volume Permissions

### Set Ownership

```yaml
services:
  app:
    user: "1000:1000"
    volumes:
      - ./data:/app/data
```

### Fix Permissions

```bash
# On host
sudo chown -R 1000:1000 ./data

# Or in container
docker exec -u root app chown -R app:app /app/data
```

## Read-Only Mounts

### Configuration Files

```yaml
volumes:
  - ./config.yml:/app/config.yml:ro
  - /etc/localtime:/etc/localtime:ro
```

### Docker Socket (Security)

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

## tmpfs Mounts

### For Temporary Data

```yaml
services:
  app:
    tmpfs:
      - /tmp
      - /run
```

### With Options

```yaml
services:
  app:
    tmpfs:
      - /tmp:size=100M,mode=1777
```

## Storage Cleanup

### Remove Unused Volumes

```bash
docker volume prune
```

### Remove All Unused Data

```bash
docker system prune -a --volumes
```

### Check Disk Usage

```bash
docker system df
docker system df -v
```

## Best Practices

### 1. Use Named Volumes for Data

```yaml
volumes:
  - dbdata:/var/lib/postgresql/data

volumes:
  dbdata:
```

### 2. Bind Mounts for Config

```yaml
volumes:
  - ./config:/app/config:ro
```

### 3. Exclude Sensitive Data from Git

```gitignore
**/data/
**/.env
**/acme.json
```

### 4. Regular Backups

```bash
# Cron job for daily backup
0 2 * * * ~/scripts/backup-docker.sh
```

### 5. Document Volume Contents

In compose file:
```yaml
volumes:
  dbdata:  # PostgreSQL database files
  uploads:  # User uploaded files
```

## Troubleshooting

### Volume Not Mounting

```bash
# Check volume exists
docker volume ls | grep myvolume

# Check mount in container
docker exec app ls -la /app/data
```

### Permission Denied

```bash
# Check ownership
ls -la ./data

# Fix
sudo chown -R $(id -u):$(id -g) ./data
```

### Disk Full

```bash
# Check usage
docker system df

# Clean up
docker system prune -a
docker volume prune
```

## Quick Reference

```bash
# List volumes
docker volume ls

# Create volume
docker volume create mydata

# Inspect volume
docker volume inspect mydata

# Remove volume
docker volume rm mydata

# Prune unused
docker volume prune

# Backup volume
docker run --rm -v mydata:/data -v $(pwd):/backup \
  alpine tar czf /backup/mydata.tar.gz -C /data .
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Storage architecture
- [04-AI-STACK](./04-AI-STACK.md) - Model storage
- [09-MAINTENANCE](./09-MAINTENANCE.md) - Backup procedures
