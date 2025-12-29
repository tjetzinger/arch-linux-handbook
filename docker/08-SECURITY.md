# 08 - Security

SSL, authentication, and container hardening.

## SSL/TLS Configuration

### Current Setup

- **Provider:** Let's Encrypt
- **Challenge:** DNS (Cloudflare)
- **Certificates:** Wildcard (*.example.com, *.example.org)
- **Min TLS:** 1.2

### TLS Options

**File:** `traefik/data/configurations/dynamic.yml`

```yaml
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

### Security Headers

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
        contentTypeNosniff: true
        browserXssFilter: true
        referrerPolicy: "strict-origin-when-cross-origin"
        frameDeny: true
```

### Test SSL Configuration

```bash
# Check SSL grade
# https://www.ssllabs.com/ssltest/

# Command line test
openssl s_client -connect ai.x1.example.com:443 -tls1_2
```

## Authentication

### Basic Auth

**Generate password hash:**

```bash
htpasswd -nb user password
# Output: user:$apr1$...
```

**Configure in dynamic.yml:**

```yaml
http:
  middlewares:
    user-auth:
      basicAuth:
        users:
          - "user:$apr1$ScS7eobG$HtsofpBIV/oB0Ge9Qn1T4."
```

**Apply to router:**

```yaml
labels:
  - traefik.http.routers.app.middlewares=user-auth@file
```

### Forward Auth (Advanced)

For external authentication:

```yaml
http:
  middlewares:
    authelia:
      forwardAuth:
        address: http://authelia:9091/api/verify?rd=https://auth.example.com
        trustForwardHeader: true
```

## Secret Management

### Environment Files

**Best Practice:** Use `.env` files instead of inline secrets.

```yaml
# docker-compose.yml
services:
  app:
    env_file:
      - .env
```

```bash
# .env
API_KEY=secret-key-here
DB_PASSWORD=database-password
```

### Git Ignore Secrets

```gitignore
**/.env
!**/.env.example
**/acme.json
**/secrets/
```

### Docker Secrets (Swarm)

For production with Docker Swarm:

```yaml
services:
  app:
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Container Hardening

### No New Privileges

```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
```

### Read-Only Root Filesystem

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /run
```

### Drop Capabilities

```yaml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only what's needed
```

### Run as Non-Root

```yaml
services:
  app:
    user: "1000:1000"
```

### Resource Limits

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          memory: 256M
```

## Docker Socket Security

### Read-Only Mount

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

### Socket Proxy (More Secure)

Use a socket proxy to limit API access:

```yaml
services:
  socket-proxy:
    image: tecnativa/docker-socket-proxy
    environment:
      CONTAINERS: 1
      IMAGES: 1
      NETWORKS: 1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  traefik:
    depends_on:
      - socket-proxy
    # Use socket-proxy:2375 instead of docker.sock
```

## Network Security

### Internal Networks

```yaml
networks:
  backend:
    internal: true  # No external access
```

### Network Isolation

```yaml
services:
  web:
    networks:
      - frontend
      - backend

  db:
    networks:
      - backend  # Only backend access

networks:
  frontend:
  backend:
    internal: true
```

## Image Security

### Use Official Images

```yaml
# Prefer
image: postgres:16

# Avoid
image: random-user/postgres
```

### Pin Versions

```yaml
# Good
image: nginx:1.25.3

# Acceptable
image: nginx:1.25

# Risky
image: nginx:latest
```

### Scan for Vulnerabilities

```bash
# Docker Scout
docker scout cves nginx:latest

# Trivy
trivy image nginx:latest
```

## Logging Security

### Limit Log Size

```yaml
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### Sensitive Data in Logs

Avoid logging sensitive data:
- Passwords
- API keys
- Personal information

## Access Control

### Limit Docker Group

The `docker` group grants root-equivalent access. Limit membership.

```bash
# Check members
grep docker /etc/group

# Remove user
sudo gpasswd -d user docker
```

### Rootless Docker (Most Secure)

For maximum security, run Docker without root.

## Security Checklist

- [ ] SSL/TLS enabled with strong ciphers
- [ ] HSTS headers configured
- [ ] Secrets in .env files, not compose
- [ ] .env files in .gitignore
- [ ] no-new-privileges enabled
- [ ] Run as non-root where possible
- [ ] Docker socket mounted read-only
- [ ] Internal networks for databases
- [ ] Resource limits configured
- [ ] Images from trusted sources
- [ ] Image versions pinned
- [ ] Logs size limited
- [ ] Docker group limited

## Quick Reference

```bash
# Generate htpasswd
htpasswd -nb user password

# Check SSL
openssl s_client -connect host:443

# Scan image
docker scout cves image:tag

# Check container security
docker inspect --format='{{.HostConfig.SecurityOpt}}' container
```

## Related

- [03-TRAEFIK](./03-TRAEFIK.md) - SSL configuration
- [06-NETWORKING](./06-NETWORKING.md) - Network isolation
- [02-DOCKER-SETUP](./02-DOCKER-SETUP.md) - Docker security settings
