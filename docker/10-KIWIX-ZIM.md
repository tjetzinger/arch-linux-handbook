# 10 - Kiwix ZIM Library (Zimi + OpenZIM MCP)

Offline Wikipedia, Stack Exchange and other Kiwix ZIM archives: a web reader for people and MCP tools for Open WebUI and Ollama.

## Overview

A ZIM file is a compressed offline copy of a website (Wikipedia, Arch Wiki, Stack Overflow, iFixit, ...). Kiwix publishes them at https://library.kiwix.org.

```
             /srv/zim  (@zim subvolume, *.zim files)
              │                          │
         rw   │                          │  ro
              ↓                          ↓
     ┌─────────────────┐       ┌──────────────────┐
     │      zimi       │       │   openzim-mcp    │  http://openzim-mcp:8000/mcp
     │ reader + library│       │  MCP over HTTP   │  (internal, bearer token)
     └────────┬────────┘       └────────┬─────────┘
              │                         │
   zim.x1.example.com        ┌────────┴─────────┐
      (via Traefik)            │    open-webui    │ ──→ ollama
                               └──────────────────┘
```

| Service | Image | Purpose | Access |
|---------|-------|---------|--------|
| zimi | `epheterson/zimi:1.15.7` | Read, search, download and update ZIMs | https://zim.x1.example.com |
| openzim-mcp | `ghcr.io/cameronrye/openzim-mcp:3.4.1` | ZIM search/read as MCP tools for LLMs | `http://openzim-mcp:8000/mcp` (proxy network only) |

### Why these two

| Option | Verdict |
|--------|---------|
| `kiwix-desktop` / `kiwix-serve` (`extra`) | Works, but basic UI and one search per archive |
| **Zimi** | Modern web UI, search across all ZIMs, built-in Kiwix catalogue with auto-update |
| `zimi-mcp` | stdio only; Open WebUI would need the `mcpo` bridge |
| **OpenZIM MCP** | Native Streamable HTTP + bearer auth, which is exactly what Open WebUI needs |
| Arviro, Volo | Alternatives (Arviro adds PDFs and OSM; Volo fakes a model and needs streaming off) |

Open WebUI (since 0.6.31) connects to MCP servers over **Streamable HTTP only**. It cannot launch stdio servers.

## Configuration

### Storage: `@zim` subvolume

ZIMs are large (English Wikipedia without images is about 50 GB) and can be downloaded again. They live in their own top-level subvolume so they stay out of Snapper snapshots of `@arch` and out of Borg (which backs up `/home/tt`, `/etc`, `/boot`, `/usr/local`, `/root`).

```bash
# One-time creation (already done 2026-11-21)
T=$(mktemp -d)
sudo mount -o subvolid=5 /dev/mapper/cryptroot "$T"
sudo btrfs subvolume create "$T/@zim"
sudo umount "$T" && rmdir "$T"
sudo mkdir -p /srv/zim
```

`/etc/fstab` (`nofail`, so a missing subvolume never blocks boot):

```
UUID=7baf5627-b3c5-4add-8b0e-fdd3488f00e0	/srv/zim	btrfs	rw,relatime,ssd,discard,space_cache=v2,subvol=/@zim,nofail	0 0
```

```bash
sudo systemctl daemon-reload && sudo mount /srv/zim
sudo chown tt:tt /srv/zim   # Zimi runs as uid 1000 and writes downloads here
```

### Compose

Both services are in `~/Workspace/containers/open-webui-stack/docker-compose.yml`:

```yaml
  openzim-mcp:
    image: ghcr.io/cameronrye/openzim-mcp:3.4.1
    container_name: openzim-mcp
    networks:
      - proxy
    volumes:
      - /srv/zim:/data:ro
    environment:
      - OPENZIM_MCP_TRANSPORT=http
      - OPENZIM_MCP_HOST=0.0.0.0
      - OPENZIM_MCP_PORT=8000
      - OPENZIM_MCP_TOOL_MODE=simple
      - OPENZIM_MCP_ALLOWED_HOSTS=["openzim-mcp"]
      - OPENZIM_MCP_AUTH_TOKEN=${ZIM_MCP_TOKEN}
    restart: unless-stopped

  zimi:
    image: epheterson/zimi:1.15.7
    container_name: zimi
    networks:
      - proxy
    volumes:
      - /srv/zim:/zims
      - ./zimi:/config
    environment:
      - ZIMI_MANAGE_PASSWORD=${ZIMI_MANAGE_PASSWORD}
      - ZIMI_LAN_ADMIN=0
      - ZIMI_PEER_DISCOVERY=0
      - ZIMI_SEED=0
    restart: unless-stopped
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.zimi-secure.entrypoints=websecure
      - traefik.http.routers.zimi-secure.rule=Host(`zim.x1.example.com`)
      - traefik.http.routers.zimi-secure.service=zimi
      - traefik.http.services.zimi.loadbalancer.server.port=8899
```

| Setting | Why |
|---------|-----|
| `OPENZIM_MCP_TOOL_MODE=simple` | The image defaults to `advanced` (8 tools). Simple mode gives one `zim_query` tool, which local models handle better |
| `OPENZIM_MCP_ALLOWED_HOSTS` | DNS-rebinding protection only accepts loopback `Host` headers by default. Open WebUI sends `Host: openzim-mcp:8000` |
| `OPENZIM_MCP_AUTH_TOKEN` | Required when binding to `0.0.0.0`; the server refuses to start without it |
| `/srv/zim:/data:ro` | The MCP server only reads |
| `ZIMI_MANAGE_PASSWORD` | Protects downloads, deletes and settings |
| `ZIMI_LAN_ADMIN=0` | Behind Traefik every client looks "local"; force the password |
| `ZIMI_PEER_DISCOVERY=0`, `ZIMI_SEED=0` | No LAN broadcast and no BitTorrent upload from a laptop |

Secrets in `.env` (see `.env.example`):

```bash
ZIM_MCP_TOKEN=        # openssl rand -hex 32
ZIMI_MANAGE_PASSWORD= # openssl rand -base64 18
```

Images are pinned, so Watchtower does not move them. Update by changing the tag.

### Traefik and DNS

`zim.x1.example.com` follows the same pattern as the other `x1` hosts:

```bash
# /etc/hosts
127.0.0.1 zim.x1.example.com
```

The Let's Encrypt certificate comes from the DNS-01 challenge (Cloudflare), see [03-TRAEFIK](./03-TRAEFIK.md).

### Open WebUI connection

Admin only. In Open WebUI: Admin Settings → Integrations → External Tool Servers → add a connection:

| Field | Value |
|-------|-------|
| Type | MCP (Streamable HTTP) |
| URL | `http://openzim-mcp:8000/mcp` |
| Auth | Bearer, key = `ZIM_MCP_TOKEN` from `.env` |
| ID | `zim` |

```bash
grep '^ZIM_MCP_TOKEN=' ~/Workspace/containers/open-webui-stack/.env | cut -d= -f2
```

Then either enable the tool per chat, or create a model under Workspace → Models with `qwen3.5:4b` as base, the `zim` tool ticked and function calling set to **Native**.

| Model | Tool calling |
|-------|--------------|
| `qwen3.5:4b` | Installed, supports tools; small, so it may skip or misuse the tool (not tested) |
| `qwen3:30b` | Stronger tool use, removed 2026-11-21 to save space; pull again if the 4B model is not good enough |

Give the model at least 16k context; tool results are a few thousand tokens each (`OLLAMA_CONTEXT_LENGTH=65536` already covers this).

## Usage

### Get ZIM files

Easiest: open https://zim.x1.example.com, log in with `ZIMI_MANAGE_PASSWORD`, and download from the built-in catalogue.

By hand (resumable, much faster than a single `curl` stream):

```bash
cd /srv/zim
aria2c --seed-time=0 --file-allocation=none --continue=true \
  "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic_YYYY-MM.zim.torrent"
```

| ZIM | Size (approx.) | Use |
|-----|----------------|-----|
| `wikipedia_en_all_nopic` | ~50 GB | Full English Wikipedia, text only, best for LLMs |
| `wikipedia_en_all_maxi` | ~110 GB | With images, nicer for reading |
| `wikipedia_en_wp1-0.8_nopic` | a few GB | Most important articles only |
| `archlinux_en_all` | small | Arch Wiki |
| `stackoverflow.com_en_all` | large | Stack Overflow Q&A |

Per its docs, `openzim-mcp` notices when a ZIM appears or is replaced. If a new archive does not show up, run `docker restart openzim-mcp`. Check sizes in the catalogue before downloading.

A 14 MB test archive (`wikipedia_en_climate_change_mini_2024-06.zim`) is in `/srv/zim` from the first setup. Delete it once real archives are in place.

### Test the MCP endpoint

```bash
docker exec open-webui python3 -c "import urllib.request; print(urllib.request.urlopen('http://openzim-mcp:8000/healthz').read())"
# b'{"status":"ok"}'
```

A request without the bearer token must return `401`.

In a chat: *"Search the offline Wikipedia for the greenhouse effect and summarize it."* `zim_query` works best with phrasing like `search for X`, `tell me about X` or `summary of X`.

## Troubleshooting

### Zimi shows `TRAEFIK DEFAULT CERT`

The DNS-01 challenge timed out (`dns01: time limit exceeded ... did not return the expected TXT record`). Cloudflare's TXT record was not visible on `1.1.1.1` in time. Restart Traefik to retry:

```bash
docker restart traefik
docker logs traefik 2>&1 | grep -i zim
```

On 2026-11-21 the first try failed and the retry worked.

### Open WebUI: "Failed to connect to MCP server"

| Check | Command / fix |
|-------|---------------|
| Container up | `docker ps --filter name=openzim-mcp` |
| Wrong type | Must be **MCP (Streamable HTTP)**, not OpenAPI |
| Wrong URL | `http://openzim-mcp:8000/mcp`, not `localhost` |
| Host header rejected | `OPENZIM_MCP_ALLOWED_HOSTS` must contain `openzim-mcp` |
| `401` | Token in Open WebUI does not match `ZIM_MCP_TOKEN` |

### Model ignores the tool

Use a model with solid native tool calling (`qwen3:30b` is stronger than `qwen3.5:4b`), set function calling to Native, and tell it in the system prompt to search the ZIM library before answering factual questions.

### Map ZIM (`maps_en_europe`) shows only a black or white page

The map uses MapLibre, which asks for a WebGL2 context with `powerPreference: "high-performance"`. With Chrome drawing through ANGLE on Vulkan (Intel Iris Xe), that request fails:

```
Failed to create WebGL2RenderingContext ... "message":"Failed to initialize WebGL"
```

Fix (2026-11-22): remove `Vulkan,VulkanFromANGLE,DefaultANGLEVulkan` from `--enable-features` in `~/.config/chrome-flags.conf`, then fully restart Chrome. ANGLE then uses OpenGL ES and the map renders. Backup of the old file: `~/.config/chrome-flags.conf.bak-20261122`.

### Zimi cannot download

`/srv/zim` must be writable by uid 1000: `sudo chown tt:tt /srv/zim`.

## Related

- [04-AI-STACK](./04-AI-STACK.md) - Ollama and Open WebUI
- [03-TRAEFIK](./03-TRAEFIK.md) - Certificates and routing
- [09-SUBVOLUME-STRATEGY](../system-recovery/09-SUBVOLUME-STRATEGY.md) - Btrfs layout incl. `@zim`
