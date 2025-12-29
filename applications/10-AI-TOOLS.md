# 10 - AI Tools

Local AI tools - ChatBox, MCP, Claude CLI, Ollama.

## Claude CLI

Anthropic's Claude Code CLI tool.

### Launch

```bash
claude
```

### Location

**Binary:** `~/.local/bin/claude` (symlink to `~/.local/share/claude/versions/`)

### Configuration

**File:** `~/.claude.json`

### Features

- Code assistance
- File editing
- Command execution
- Multi-turn conversations
- MCP server integration

### Usage

```bash
# Start interactive session
claude

# With initial prompt
claude "explain this code"

# In specific directory
cd /path/to/project && claude
```

### Statusline

Claude Code displays a statusline showing context usage percentage. This can be customized.

**Check context accurately:**
```bash
/context
```

### Known Issues

| Issue | Description | Workaround |
|-------|-------------|------------|
| Statusline shows wrong % | Statusline displays inflated context usage (e.g., 86%) while `/context` shows actual (e.g., 39%) | Use `/context` command for accurate readings |
| "TBD" in context display | After restart, context remaining may show "TBD" | Run `/context` or `/clear` |
| Cumulative token count | Statusline JSON uses cumulative tokens instead of current context | Trust `/context` output |

**Related GitHub Issues:**

| Issue | Description |
|-------|-------------|
| [#14348](https://github.com/anthropics/claude-code/issues/14348) | `usage_context` reports incorrect percentage |
| [#13783](https://github.com/anthropics/claude-code/issues/13783) | Statusline JSON contains cumulative tokens |
| [#11335](https://github.com/anthropics/claude-code/issues/11335) | Display shows 0% when ~50% available |
| [#9636](https://github.com/anthropics/claude-code/issues/9636) | Wrong context amount and autocompact |

**Rule of thumb:** Always use `/context` for accurate token usage, not the statusline.

## MCP (Model Context Protocol)

Protocol for connecting AI models to external tools.

### Configuration

**File:** `~/.config/mcp/mcp.json`

### Configured Servers

| Server | Purpose |
|--------|---------|
| Exa | Web search integration |

### Usage

MCP servers provide Claude CLI with:
- Web search capabilities
- External data access
- Tool integration

## ChatBox

AI chat client application.

### Launch

```bash
# GUI application
chatbox
```

### Configuration

**Directory:** `~/.config/xyz.chatboxapp.app/`

```
xyz.chatboxapp.app/
├── config.json           # Settings
├── Cache/                # Cached data
├── blob_storage/         # Binary data
└── Session Storage/      # Sessions
```

### Features

- Multiple AI provider support
- Chat history
- Customizable prompts
- Export conversations

### Supported Providers

- OpenAI
- Anthropic (Claude)
- Ollama (local)
- Custom endpoints

## Ollama (Docker)

Ollama runs as a Docker container.

### Alias

```bash
alias ollama='docker exec ollama ollama'
```

### Commands

```bash
# List models
ollama list

# Run model
ollama run llama2

# Pull model
ollama pull mistral

# Remove model
ollama rm model-name
```

### API

```bash
# Default endpoint (via Docker)
http://localhost:11434

# Generate
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Hello"
}'
```

See [../docker/04-AI-STACK](../docker/04-AI-STACK.md) for full Ollama documentation.

## Open WebUI

Web interface for AI models (Docker).

### Access

```
https://chat.fiffeek.com
```

Or via Traefik reverse proxy.

See [../docker/04-AI-STACK](../docker/04-AI-STACK.md).

## Integration

### ChatBox + Ollama

ChatBox can connect to Ollama's local API:

1. Ensure Ollama container is running
2. In ChatBox, add custom endpoint: `http://localhost:11434`
3. Use local models through ChatBox interface

### Claude CLI + MCP

Claude CLI automatically loads MCP servers from `~/.config/mcp/mcp.json`.

### VS Code + AI

VS Code: Claude Code extension available.

## Quick Reference

```bash
# Claude CLI
claude                 # Interactive mode
claude "prompt"        # With prompt

# ChatBox
chatbox                # Launch GUI

# Ollama (Docker)
ollama list            # List models
ollama run llama2      # Run model

# Config locations
~/.claude.json
~/.config/mcp/mcp.json
~/.config/xyz.chatboxapp.app/
```

## Related

- [../docker/04-AI-STACK](../docker/04-AI-STACK.md) - Docker AI services
- [04-EDITORS](./04-EDITORS.md) - VS Code
