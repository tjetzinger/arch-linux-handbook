# 01 - Overview

Docker container architecture and infrastructure.

## Architecture

```
                         Internet
                            │
                      Cloudflare DNS
                            │
                    ┌───────┴───────┐
                    │   Traefik     │ :80, :443
                    │  (proxy)      │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
         ┌────┴────┐  ┌─────┴─────┐  ┌────┴────┐
         │ AI Stack│  │ Services  │  │  Apps   │
         └────┬────┘  └─────┬─────┘  └────┬────┘
              │             │             │
    ┌─────────┼─────────┐   │             │
    │         │         │   │             │
 ollama   open-webui litellm│             │
    │         │         │   │             │
    └─────────┴────┬────┘   │             │
                   │        │             │
              ┌────┴────┐ ┌─┴──┐      ┌───┴───┐
              │ postgres│ │n8n │      │ nginx │
              └─────────┘ └────┘      └───────┘
```

## Container Stack

### Core Infrastructure

| Container | Image | Purpose |
|-----------|-------|---------|
| traefik | traefik:latest | Reverse proxy, SSL termination |
| portainer | portainer-ce:latest | Container management UI |
| watchtower | watchtower:latest | Automatic container updates |

### AI/ML Stack

| Container | Image | Purpose |
|-----------|-------|---------|
| ollama | ollama:latest | Local LLM inference |
| open-webui | open-webui:main | AI chat interface |
| litellm | litellm-database | LLM proxy/gateway |
| postgres | postgres:16 | Database for LiteLLM |

### Services

| Container | Image | Purpose |
|-----------|-------|---------|
| n8n | n8n:latest | Workflow automation |
| nginx | nginx:latest | Static web server |
| firefox | linuxserver/firefox | Browser in container |

## Network Topology

```
┌─────────────────────────────────────────────────────┐
│                    proxy network                     │
│                   (172.22.0.0/16)                   │
│                                                      │
│  traefik ─── open-webui ─── ollama ─── litellm     │
│     │            │                        │          │
│     ├── n8n      │                    postgres      │
│     ├── portainer│                                  │
│     └── nginx    │                                  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                   bridge (default)                   │
│                   (172.17.0.0/16)                   │
│                                                      │
│              (standalone containers)                 │
└─────────────────────────────────────────────────────┘
```

## Domain Structure

| Domain | Service |
|--------|---------|
| traefik.x1.example.com | Traefik dashboard |
| portainer.x1.example.com | Portainer UI |
| ai.x1.example.com | Open WebUI |
| llm.x1.example.com | LiteLLM API |
| n8n.x1.example.com | n8n workflows |
| *.example.org | Secondary domain |

## SSL Certificates

- **Provider:** Let's Encrypt
- **Challenge:** DNS (Cloudflare)
- **Type:** Wildcard certificates
- **Domains:** *.example.com, *.example.org

## Compose Files

```
~/Workspace/containers/
├── .git/                    # Version controlled
├── .gitignore               # Excludes secrets, data
├── traefik/
│   ├── docker-compose.yml
│   ├── .env                 # Cloudflare credentials
│   └── data/
│       ├── traefik.yml      # Static config
│       ├── acme.json        # Certificates
│       └── configurations/
│           └── dynamic.yml  # Middlewares, TLS
├── portainer/
│   ├── docker-compose.yml
│   └── data/                # Portainer data
├── open-webui-stack/
│   ├── docker-compose.yml
│   ├── .env                 # API keys
│   ├── ollama/              # Models
│   ├── open-webui/          # WebUI data
│   └── db/                  # PostgreSQL data
├── n8n/
│   ├── docker-compose.yml
│   └── local-files/
├── watchtower/
│   └── docker-compose.yml
└── firefox/
    └── docker-compose.yml
```

## Resource Usage

```bash
# Check resource usage
docker stats --no-stream
```

| Container | Memory | CPU |
|-----------|--------|-----|
| ollama | ~4GB (with models) | Variable |
| open-webui | ~500MB | Low |
| litellm | ~500MB | Low |
| postgres | ~200MB | Low |
| traefik | ~50MB | Low |
| n8n | ~300MB | Low |

## Service Dependencies

```
traefik (standalone)
    │
    └── All other services depend on traefik for routing

open-webui
    ├── ollama (LLM backend)
    └── litellm (API proxy)
           └── postgres (database)

n8n (standalone)

portainer (standalone)

watchtower (standalone)
```

## Ports

### Exposed Ports

| Port | Service | Protocol |
|------|---------|----------|
| 80 | Traefik | HTTP (redirects to 443) |
| 443 | Traefik | HTTPS |
| 1080 | Traefik | SOCKS5 proxy |

### Internal Ports

| Port | Service |
|------|---------|
| 8080 | Open WebUI |
| 11434 | Ollama |
| 4000 | LiteLLM |
| 5678 | n8n |
| 9000 | Portainer |
| 5432 | PostgreSQL |

## Quick Commands

```bash
# All containers
docker ps -a

# Specific stack
cd ~/Workspace/containers/open-webui-stack
docker compose ps
docker compose logs -f

# Resource usage
docker stats

# Disk usage
docker system df

# Clean up
docker system prune -a
```

## Related

- [02-DOCKER-SETUP](./02-DOCKER-SETUP.md) - Installation
- [03-TRAEFIK](./03-TRAEFIK.md) - Proxy configuration
- [06-NETWORKING](./06-NETWORKING.md) - Network details
