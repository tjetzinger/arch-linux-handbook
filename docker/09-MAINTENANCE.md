# 09 - Maintenance

Updates, backups, logs, and troubleshooting.

## Updates

### Watchtower (Automatic)

Watchtower automatically updates containers every 5 minutes.

```bash
# Check update logs
docker logs watchtower

# Disable for specific container
labels:
  - com.centurylinklabs.watchtower.enable=false
```

### Manual Update

```bash
cd ~/Workspace/containers/<service>

# Pull latest images
docker compose pull

# Recreate containers
docker compose up -d

# Remove old images
docker image prune -a
```

### Update All Stacks

```bash
#!/bin/bash
for dir in ~/Workspace/containers/*/; do
    if [ -f "$dir/docker-compose.yml" ]; then
        echo "Updating $dir"
        cd "$dir"
        docker compose pull
        docker compose up -d
    fi
done
docker image prune -f
```

## Backups

### Backup Script

```bash
#!/bin/bash
# backup-docker.sh

BACKUP_DIR="/backup/docker/$(date +%Y%m%d)"
CONTAINERS_DIR="$HOME/Workspace/containers"

mkdir -p "$BACKUP_DIR"

# Backup compose files and configs
tar czf "$BACKUP_DIR/containers-config.tar.gz" \
    --exclude='*/ollama/models/*' \
    --exclude='*/db/*' \
    --exclude='*/.env' \
    "$CONTAINERS_DIR"

# Backup named volumes
for vol in $(docker volume ls -q); do
    docker run --rm \
        -v "$vol":/data:ro \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf "/backup/$vol.tar.gz" -C /data .
done

# Backup PostgreSQL
docker exec postgres pg_dump -U llmproxy litellm > "$BACKUP_DIR/litellm.sql"

echo "Backup completed: $BACKUP_DIR"
```

### Restore Volume

```bash
docker run --rm \
    -v myvolume:/data \
    -v $(pwd):/backup \
    alpine tar xzf /backup/myvolume.tar.gz -C /data
```

### Restore PostgreSQL

```bash
cat backup.sql | docker exec -i postgres psql -U llmproxy litellm
```

## Logs

### View Logs

```bash
# Single container
docker logs <container>
docker logs -f <container>          # Follow
docker logs --tail 100 <container>  # Last 100 lines
docker logs --since 1h <container>  # Last hour

# Compose stack
docker compose logs
docker compose logs -f
docker compose logs <service>
```

### Log Rotation

```yaml
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### Log Locations

```bash
# Container logs
/var/lib/docker/containers/<id>/<id>-json.log

# Compose logs
docker compose logs
```

### Search Logs

```bash
docker logs <container> 2>&1 | grep "error"
docker logs <container> 2>&1 | grep -i "warning\|error"
```

## Monitoring

### Resource Usage

```bash
# Real-time stats
docker stats

# Snapshot
docker stats --no-stream

# Specific containers
docker stats traefik nginx ollama
```

### Disk Usage

```bash
# Overview
docker system df

# Detailed
docker system df -v

# Check specific volumes
du -sh /var/lib/docker/volumes/*
```

### Health Checks

```bash
# Container health
docker inspect --format='{{.State.Health.Status}}' <container>

# All container status
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## Cleanup

### Remove Unused Resources

```bash
# Containers, networks, images
docker system prune

# Including volumes (CAREFUL!)
docker system prune -a --volumes

# Just dangling images
docker image prune

# Just unused volumes
docker volume prune
```

### Clean Build Cache

```bash
docker builder prune
```

### Scheduled Cleanup

```bash
# Cron job (weekly)
0 3 * * 0 docker system prune -af --volumes
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs <container>

# Check compose logs
docker compose logs

# Inspect container
docker inspect <container>

# Check events
docker events --since 10m
```

### Network Issues

```bash
# Check network
docker network inspect proxy

# Test connectivity
docker exec <container> ping other-container
docker exec <container> curl http://service:port

# Check DNS
docker exec <container> cat /etc/resolv.conf
```

### Disk Full

```bash
# Check usage
docker system df
df -h /var/lib/docker

# Clean up
docker system prune -a
docker volume prune
```

### Container Using Too Much Memory

```bash
# Check memory
docker stats <container>

# Add limits
docker update --memory 512m <container>

# Or in compose
deploy:
  resources:
    limits:
      memory: 512M
```

### Service Unavailable (503)

```bash
# Check container is running
docker ps | grep <service>

# Check Traefik routing
docker logs traefik | grep <service>

# Check container logs
docker logs <service>

# Verify network
docker network inspect proxy | grep <service>
```

### SSL Certificate Issues

```bash
# Check Traefik logs
docker logs traefik | grep -i acme

# Regenerate certificates
rm ~/Workspace/containers/traefik/data/acme.json
docker restart traefik
```

## Common Commands

### Container Management

```bash
# Start/Stop/Restart
docker start <container>
docker stop <container>
docker restart <container>

# Remove
docker rm <container>
docker rm -f <container>  # Force

# Shell access
docker exec -it <container> sh
docker exec -it <container> bash
```

### Compose Operations

```bash
cd ~/Workspace/containers/<service>

docker compose up -d       # Start
docker compose down        # Stop
docker compose restart     # Restart
docker compose logs -f     # Logs
docker compose pull        # Update images
docker compose ps          # Status
```

### Inspect

```bash
docker inspect <container>
docker inspect <container> | jq '.[0].NetworkSettings'
docker inspect <container> | jq '.[0].Mounts'
```

## Maintenance Schedule

### Daily
- Check Watchtower logs for updates
- Review container status

### Weekly
- Review disk usage
- Clean unused resources
- Check for security updates

### Monthly
- Full backup of volumes
- Review and rotate logs
- Update base images
- Review access/credentials

## Quick Reference

```bash
# Status
docker ps -a
docker compose ps

# Logs
docker logs -f <container>
docker compose logs -f

# Updates
docker compose pull && docker compose up -d

# Cleanup
docker system prune -a

# Backup
docker exec postgres pg_dump -U user db > backup.sql

# Resources
docker stats
docker system df
```

## Related

- [02-DOCKER-SETUP](./02-DOCKER-SETUP.md) - Configuration
- [05-SERVICES](./05-SERVICES.md) - Watchtower
- [07-STORAGE](./07-STORAGE.md) - Volume backups
