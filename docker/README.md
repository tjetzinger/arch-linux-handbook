# Docker

Docker container infrastructure with Traefik reverse proxy.

## Current Setup

| Component | Details |
|-----------|---------|
| Docker | 29.1.1 |
| Compose | 2.40.3 |
| Storage | overlay2 |
| Proxy | Traefik with Let's Encrypt |

## Running Services

| Container | Purpose | URL |
|-----------|---------|-----|
| traefik | Reverse proxy + SSL | traefik.x1.example.com |
| portainer | Docker management | portainer.x1.example.com |
| open-webui | AI chat interface | ai.x1.example.com |
| ollama | Local LLM server | (internal) |
| litellm | LLM proxy/router | llm.x1.example.com |
| n8n | Workflow automation | n8n.x1.example.com |
| postgres | Database | (internal) |
| watchtower | Auto-updates | (internal) |
| nginx | Web server | (via Traefik) |

## Quick Reference

```bash
# List containers
docker ps -a

# View logs
docker logs <container> -f

# Compose operations
cd ~/Workspace/containers/<service>
docker compose up -d
docker compose down
docker compose logs -f

# Portainer UI
https://portainer.x1.example.com
```

## Documentation

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | Architecture and infrastructure |
| [02-DOCKER-SETUP](./02-DOCKER-SETUP.md) | Installation and configuration |
| [03-TRAEFIK](./03-TRAEFIK.md) | Reverse proxy and SSL |
| [04-AI-STACK](./04-AI-STACK.md) | Ollama, Open WebUI, LiteLLM |
| [05-SERVICES](./05-SERVICES.md) | n8n, Portainer, Watchtower |
| [06-NETWORKING](./06-NETWORKING.md) | Docker networks |
| [07-STORAGE](./07-STORAGE.md) | Volumes and persistence |
| [08-SECURITY](./08-SECURITY.md) | SSL, auth, hardening |
| [09-MAINTENANCE](./09-MAINTENANCE.md) | Updates, logs, troubleshooting |

## Compose Files Location

```
~/Workspace/containers/
├── traefik/          # Reverse proxy
├── portainer/        # Docker management
├── open-webui-stack/ # AI stack
├── n8n/              # Workflow automation
├── watchtower/       # Auto-updates
└── firefox/          # Browser container
```

## Related

- [Networking - Docker Integration](../networking/05-NETWORK-INTEGRATION.md#docker-integration)
- [Virtualization](../virtualization/) - VM alternatives
