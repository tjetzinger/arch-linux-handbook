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

### What Actually Backs Up Docker Data

Borg (`borg-backup.timer`, daily, script `/usr/local/bin/borg-backup-system`) backs up `/home/tt`, `/etc`, `/boot`, `/usr/local` and `/root`. See [system-recovery/07-BORG-BACKUP-AUTOMATION](../system-recovery/07-BORG-BACKUP-AUTOMATION.md).

| Data | Location | In Borg |
|------|----------|---------|
| Compose files, configs, `.env` files | `~/Workspace/containers/` | yes |
| Open WebUI (`webui.db`), Postgres, Portainer, Traefik `acme.json` | bind mounts under `~/Workspace/containers/` | yes |
| Ollama models | `open-webui-stack/ollama` | no (excluded, re-downloadable) |
| n8n workflows and credentials | named volume `n8n_n8n_data` in `/var/lib/docker/volumes/` | **no** |
| `tymeslot_trial_pg`, `tymeslot_trial_data` | named volumes, no container uses them | no |

Named volumes live in `/var/lib/docker/volumes/`, outside the Borg paths. To cover n8n, add `/var/lib/docker/volumes/n8n_n8n_data` to the paths in `borg-backup-system`, or export the volume with the command in [07-STORAGE - Backup Named Volume](./07-STORAGE.md#backup-named-volume).

Note: Borg copies live database files. Postgres is stopped; SQLite (`webui.db`) is usually fine but not guaranteed consistent while Open WebUI writes.

### Example Backup Script (not deployed)

A standalone script for the case without Borg. It is **not** installed: there is no `~/scripts/backup-docker.sh` and no cron job.

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

### Containers Stuck in "Created" After a System Update

**Symptoms:** Containers show `state=created` and never start. `docker inspect`
reveals `State.Error`:

```
failed to create task for container: failed to start shim: start failed:
failed to create TTRPC connection: unsupported protocol: Yunix
```

**Cause:** The container's stored runtime spec was created under an older
`containerd`/`runc` and is incompatible after a rolling upgrade (e.g. Arch/CachyOS
`pacman -Syu` bumping `containerd` and `runc`). Restarting the Docker daemon alone
does **not** fix it — the per-container shim state must be regenerated.

```bash
# Confirm: which containers are stuck and why
docker ps -aq | xargs -r docker inspect \
  --format '{{.Name}} state={{.State.Status}} exit={{.State.ExitCode}} error="{{.State.Error}}"'

# Check whether containerd/runc were upgraded recently
grep -iE 'upgraded (docker|containerd|runc)' /var/log/pacman.log | tail
```

**Fix:** Recreate the containers under the current runtime (regenerates the spec):

```bash
cd /path/to/compose/stack
docker compose up -d --force-recreate
# For plain `docker run` containers: docker rm <name> then re-run it
```

### Crashlooping Container Storms the Host Network (Chrome `ERR_NETWORK_CHANGED`)

**Symptoms:** In **Chrome** (not Firefox), the first load of a URL frequently
fails and a refresh fixes it. A `chrome://net-export` NetLog shows many
`NETWORK_CHANGED` notifications and `ERR_NETWORK_CHANGED` / QUIC pool teardowns.

**Cause:** A container in a **restart loop** (`restart: always` + a failing
dependency) recreates its `veth` interface on every restart. Each veth
create/destroy emits RTNETLINK link/route/address events, which Chrome's Linux
`NetworkChangeNotifier` treats as network changes and reacts to by aborting
in-flight navigations. Firefox does not abort on these events, so it is immune.
See [networking/06-TROUBLESHOOTING.md](../networking/06-TROUBLESHOOTING.md).

```bash
# Find the crashlooping container (high RestartCount)
docker ps -aq | xargs -r docker inspect \
  --format '{{.Name}} restarts={{.RestartCount}} state={{.State.Status}} policy={{.HostConfig.RestartPolicy.Name}}' \
  | sort -t= -k2 -rn | head

# Watch the churn it causes on the host (veth/bridge flapping)
timeout 20 ip monitor route address link | grep -iE 'veth|br-'

# Why is it crashing?
docker logs --tail 30 <container>
```

**Fix:**
```bash
# Immediate: stop the loop (churn stops instantly)
docker stop <container>

# Proper: start its missing dependency, then the container
docker start <dependency> && docker start <container>
```

**Prevent recurrence:** in the compose file, cap the restart policy and gate on
the dependency's health so a downstream outage can't storm the host network:

```yaml
services:
  app:
    restart: on-failure:5        # not "always"
    depends_on:
      db:
        condition: service_healthy
```

> **Note on Watchtower:** auto-updating images that use `latest`/nightly tags
> (e.g. `...-nightly`) can pull a broken build that then crashloops. Pin stable
> tags for critical services, or exclude them from Watchtower.

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
