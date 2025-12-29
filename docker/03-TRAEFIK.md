# 03 - Traefik

Reverse proxy with automatic SSL certificates.

## Current Configuration

| Setting | Value |
|---------|-------|
| Image | traefik:latest |
| SSL Provider | Let's Encrypt |
| DNS Challenge | Cloudflare |
| Domains | *.example.com, *.example.org |

## Architecture

```
Internet
    │
    ↓
┌─────────────────────────────────────┐
│            Traefik                   │
│  ┌─────────┐  ┌─────────┐           │
│  │  :80    │  │  :443   │  :1080    │
│  │ (HTTP)  │→ │ (HTTPS) │  (SOCKS)  │
│  └─────────┘  └─────────┘           │
│         │                            │
│    Let's Encrypt                     │
│    (Cloudflare DNS)                  │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┐
    ↓          ↓          ↓
 open-webui   n8n    portainer
```

## File Structure

```
~/Workspace/containers/traefik/
├── docker-compose.yml      # Container definition
├── .env                    # Cloudflare credentials
├── .env.example            # Template
└── data/
    ├── traefik.yml         # Static configuration
    ├── acme.json           # Certificates (chmod 600)
    └── configurations/
        └── dynamic.yml     # Middlewares, TLS options
```

## Docker Compose

```yaml
services:
  traefik:
    image: "traefik:latest"
    container_name: traefik
    restart: always
    security_opt:
      - "no-new-privileges:true"
    networks:
      - proxy
    ports:
      - "80:80"
      - "443:443"
      - "1080:1080"
    env_file:
      - .env
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./data/traefik.yml:/traefik.yml:ro"
      - "./data/acme.json:/acme.json"
      - "./data/configurations:/configurations"
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.traefik-secure.entrypoints=websecure
      - traefik.http.routers.traefik-secure.rule=Host(`traefik.x1.example.com`)
      - traefik.http.routers.traefik-secure.service=api@internal
      - traefik.http.routers.traefik-secure.middlewares=user-auth@file
      - traefik.http.routers.traefik-secure.tls=true
      - traefik.http.routers.traefik-secure.tls.certresolver=letsencrypt

networks:
  proxy:
    external: true
```

## Static Configuration

**File:** `data/traefik.yml`

```yaml
api:
  dashboard: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure

  websecure:
    address: ":443"
    http:
      middlewares:
        - secureHeaders@file
      tls:
        certResolver: letsencrypt

  socks5-tcp-proxy:
    address: ":1080"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    filename: /configurations/dynamic.yml

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: acme.json
      keyType: EC384
      dnsChallenge:
        provider: cloudflare
        resolvers: 1.1.1.1:53
```

## Dynamic Configuration

**File:** `data/configurations/dynamic.yml`

```yaml
http:
  middlewares:
    secureHeaders:
      headers:
        sslRedirect: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000

    user-auth:
      basicAuth:
        users:
          - "user:$apr1$hash..."

tls:
  options:
    default:
      cipherSuites:
        - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
      minVersion: VersionTLS12
```

## Environment Variables

**File:** `.env`

```bash
CF_API_EMAIL=your-email@example.com
CF_DNS_API_TOKEN=your-cloudflare-api-token
```

Get token from: https://dash.cloudflare.com/profile/api-tokens

Required permissions:
- Zone:DNS:Edit (for your domains)

## Adding a Service

### Via Docker Labels

```yaml
services:
  myapp:
    image: myapp:latest
    networks:
      - proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.myapp-secure.entrypoints=websecure
      - traefik.http.routers.myapp-secure.rule=Host(`myapp.x1.example.com`)
      - traefik.http.routers.myapp-secure.service=myapp
      - traefik.http.services.myapp.loadbalancer.server.port=8080

networks:
  proxy:
    external: true
```

### Label Reference

| Label | Purpose |
|-------|---------|
| `traefik.enable=true` | Enable Traefik for this container |
| `traefik.docker.network=proxy` | Network for routing |
| `traefik.http.routers.<name>.entrypoints` | Entry point (web/websecure) |
| `traefik.http.routers.<name>.rule` | Routing rule |
| `traefik.http.routers.<name>.service` | Service name |
| `traefik.http.services.<name>.loadbalancer.server.port` | Container port |
| `traefik.http.routers.<name>.middlewares` | Apply middlewares |
| `traefik.http.routers.<name>.tls=true` | Enable TLS |

## Routing Rules

### Host-Based

```yaml
- traefik.http.routers.app.rule=Host(`app.example.com`)
```

### Path-Based

```yaml
- traefik.http.routers.app.rule=Host(`example.com`) && PathPrefix(`/app`)
```

### Multiple Hosts

```yaml
- traefik.http.routers.app.rule=Host(`app.example.com`) || Host(`app.other.com`)
```

## Middlewares

### Basic Auth

```yaml
# In dynamic.yml
http:
  middlewares:
    user-auth:
      basicAuth:
        users:
          - "user:$apr1$..."
```

Generate password:
```bash
htpasswd -nb user password
```

Apply to router:
```yaml
- traefik.http.routers.app.middlewares=user-auth@file
```

### Rate Limiting

```yaml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        burst: 50
```

### IP Whitelist

```yaml
http:
  middlewares:
    ip-whitelist:
      ipWhiteList:
        sourceRange:
          - "192.168.1.0/24"
          - "10.0.0.0/8"
```

### Redirect

```yaml
http:
  middlewares:
    redirect-www:
      redirectRegex:
        regex: "^https://www\\.(.*)"
        replacement: "https://${1}"
```

## Certificates

### Wildcard Certificates

```yaml
# In docker-compose.yml labels
- traefik.http.routers.app.tls.domains[0].main=example.com
- traefik.http.routers.app.tls.domains[0].sans=*.example.com
```

### Check Certificates

```bash
# View acme.json
cat data/acme.json | jq '.letsencrypt.Certificates'

# Or check via Traefik API
curl -s http://localhost:8080/api/http/routers | jq '.'
```

### Renew Certificates

Certificates auto-renew. To force:
```bash
# Delete and restart
rm data/acme.json
docker compose restart traefik
```

## Dashboard

Access: https://traefik.x1.example.com

Protected by basic auth (user-auth middleware).

### Dashboard Features

- HTTP Routers
- HTTP Services
- HTTP Middlewares
- TLS configuration
- Entry points

## Troubleshooting

### Check Logs

```bash
docker logs traefik -f
```

### Common Issues

**Certificate errors:**
```bash
# Check acme.json permissions
chmod 600 data/acme.json

# Check Cloudflare token
# Ensure DNS zone permissions
```

**Container not routed:**
```bash
# Check container is on proxy network
docker network inspect proxy

# Check labels
docker inspect <container> | jq '.[0].Config.Labels'
```

**503 Service Unavailable:**
```bash
# Check container is running
docker ps

# Check port is correct
docker port <container>
```

### Debug Mode

Add to traefik.yml:
```yaml
log:
  level: DEBUG
```

## Quick Reference

```bash
# Restart Traefik
cd ~/Workspace/containers/traefik
docker compose restart

# View logs
docker logs traefik -f

# Check routers
curl -s localhost:8080/api/http/routers | jq '.'

# Regenerate certificates
rm data/acme.json && docker compose restart

# Add new service
# Add labels to container, restart
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Architecture
- [08-SECURITY](./08-SECURITY.md) - SSL and security
- [04-AI-STACK](./04-AI-STACK.md) - AI services routing
