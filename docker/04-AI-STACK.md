# 04 - AI Stack

Ollama, Open WebUI, and LiteLLM for local AI inference.

## Architecture

```
                    User
                      │
                      ↓
              ┌───────────────┐
              │   Open WebUI  │  ai.x1.example.com
              │   (Chat UI)   │
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        ↓                           ↓
┌───────────────┐           ┌───────────────┐
│    Ollama     │           │   LiteLLM     │  llm.x1.example.com
│  (Local LLM)  │           │ (API Proxy)   │
└───────────────┘           └───────┬───────┘
                                    │
                            ┌───────┴───────┐
                            │   PostgreSQL  │
                            │  (Database)   │
                            └───────────────┘
```

## Components

| Service | Purpose | Port |
|---------|---------|------|
| ollama | Local LLM inference (llama, mistral, etc.) | 11434 |
| open-webui | ChatGPT-like web interface | 8080 |
| litellm | LLM API proxy/gateway | 4000 |
| postgres | Database for LiteLLM | 5432 |

## Compose File

**Location:** `~/Workspace/containers/open-webui-stack/docker-compose.yml`

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ./ollama:/root/.ollama
    environment:
      - OLLAMA_FLASH_ATTENTION=true
      - OLLAMA_KV_CACHE_TYPE=f16
    networks:
      - proxy
    restart: unless-stopped

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    networks:
      - proxy
    volumes:
      - ./open-webui:/app/backend/data
    depends_on:
      - ollama
      - litellm
    environment:
      - OLLAMA_API_BASE_URL=http://ollama:11434
      - WEBUI_SECRET_KEY=your-secret-key
    restart: unless-stopped
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.open-webui-secure.entrypoints=websecure
      - traefik.http.routers.open-webui-secure.rule=Host(`ai.x1.example.com`)
      - traefik.http.routers.open-webui-secure.service=open-webui
      - traefik.http.services.open-webui.loadbalancer.server.port=8080

  litellm:
    image: ghcr.io/berriai/litellm-database:main-v1.63.6-nightly
    container_name: litellm
    env_file:
      - .env
    volumes:
      - ./config.yml:/app/config.yaml
    command: --config /app/config.yaml --port 4000
    restart: always
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
    networks:
      - proxy
    depends_on:
      - db
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.litellm-secure.entrypoints=websecure
      - traefik.http.routers.litellm-secure.rule=Host(`llm.x1.example.com`)
      - traefik.http.routers.litellm-secure.service=litellm
      - traefik.http.services.litellm.loadbalancer.server.port=4000

  db:
    image: postgres:16
    container_name: postgres
    restart: always
    networks:
      - proxy
    volumes:
      - ./db:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: litellm
      POSTGRES_USER: llmproxy
      POSTGRES_PASSWORD: dbpassword
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d litellm -U llmproxy"]
      interval: 1s
      timeout: 5s
      retries: 10

networks:
  proxy:
    external: true
```

## Ollama

### Models Location

```bash
~/Workspace/containers/open-webui-stack/ollama/models/
```

### Pull Models

```bash
# Via docker exec
docker exec -it ollama ollama pull llama3.2
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull codellama

# Or via API
curl http://localhost:11434/api/pull -d '{"name": "llama3.2"}'
```

### List Models

```bash
docker exec -it ollama ollama list
```

### Remove Models

```bash
docker exec -it ollama ollama rm <model-name>
```

### Model Storage

Models are stored in:
```
./ollama/models/blobs/      # Model files
./ollama/models/manifests/  # Model metadata
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| OLLAMA_FLASH_ATTENTION | Enable flash attention (faster) |
| OLLAMA_KV_CACHE_TYPE | Cache type (f16, q8_0, q4_0) |
| OLLAMA_NUM_PARALLEL | Parallel requests |
| OLLAMA_MAX_LOADED_MODELS | Max models in memory |

## Open WebUI

### Access

URL: https://ai.x1.example.com

### Features

- ChatGPT-like interface
- Multiple model support
- Conversation history
- Document upload (RAG)
- Model switching
- User management

### Data Location

```
./open-webui/
├── webui.db          # SQLite database
├── uploads/          # Uploaded files
├── cache/            # Cache files
└── vector_db/        # RAG embeddings
```

### Configuration

Environment variables in compose:

| Variable | Purpose |
|----------|---------|
| OLLAMA_API_BASE_URL | Ollama server URL |
| WEBUI_SECRET_KEY | Session encryption key |
| ENABLE_SIGNUP | Allow new registrations |
| DEFAULT_USER_ROLE | Default role for new users |

### Admin Setup

First user to register becomes admin.

## LiteLLM

### Purpose

LiteLLM provides:
- Unified API for multiple LLM providers
- API key management
- Request logging
- Cost tracking
- Load balancing

### Configuration

**File:** `config.yml`

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: openai/gpt-4
      api_key: os.environ/OPENAI_API_KEY

  - model_name: claude-3
    litellm_params:
      model: anthropic/claude-3-opus
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: ollama-llama
    litellm_params:
      model: ollama/llama3.2
      api_base: http://ollama:11434
```

### Environment Variables

**File:** `.env`

```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
LITELLM_MASTER_KEY=sk-...
```

### API Usage

```bash
# List models
curl https://llm.x1.example.com/models \
  -H "Authorization: Bearer sk-litellm-key"

# Chat completion
curl https://llm.x1.example.com/chat/completions \
  -H "Authorization: Bearer sk-litellm-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ollama-llama",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## PostgreSQL

### Database

Used by LiteLLM for:
- API key storage
- Request logging
- User management
- Cost tracking

### Access Database

```bash
docker exec -it postgres psql -U llmproxy -d litellm
```

### Backup Database

```bash
docker exec postgres pg_dump -U llmproxy litellm > backup.sql
```

## GPU Support (Optional)

### For Ollama with GPU

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

### Check GPU

```bash
docker exec -it ollama nvidia-smi
```

## Management

### Start Stack

```bash
cd ~/Workspace/containers/open-webui-stack
docker compose up -d
```

### View Logs

```bash
docker compose logs -f
docker logs ollama -f
docker logs open-webui -f
```

### Stop Stack

```bash
docker compose down
```

### Update

```bash
docker compose pull
docker compose up -d
```

## Troubleshooting

### Ollama Not Responding

```bash
# Check container
docker logs ollama

# Restart
docker restart ollama

# Check memory (models need RAM)
docker stats ollama
```

### Open WebUI Can't Connect to Ollama

```bash
# Check network
docker network inspect proxy

# Test connection from open-webui
docker exec open-webui curl http://ollama:11434/api/tags
```

### Model Loading Slow

- Check available RAM
- Consider smaller models (7B vs 70B)
- Enable flash attention

### Database Connection Error

```bash
# Check postgres is healthy
docker ps | grep postgres

# Check connection
docker exec litellm curl db:5432
```

## Quick Reference

```bash
# Pull new model
docker exec ollama ollama pull llama3.2

# List models
docker exec ollama ollama list

# View logs
docker compose logs -f

# Restart stack
docker compose restart

# Update images
docker compose pull && docker compose up -d
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Architecture
- [03-TRAEFIK](./03-TRAEFIK.md) - Routing configuration
- [07-STORAGE](./07-STORAGE.md) - Data persistence
