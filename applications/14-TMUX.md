# 14 - Tmux

Terminal multiplexer with session persistence, configured for Kitty, Warp, and SSH.

## Overview

| Component | Choice |
|-----------|--------|
| Version | tmux 3.6a |
| Plugin Manager | TPM (Tmux Plugin Manager) |
| Clipboard | OSC 52 + wl-copy (Wayland) |
| Session Persistence | tmux-resurrect + tmux-continuum |

## Configuration

**File:** `~/.tmux.conf`

### Auto-Start

**File:** `~/.config/zshrc/01-tmux`

Tmux auto-starts on terminal launch using **grouped sessions**:
- First terminal creates base session (`main` or `ssh-<hostname>`)
- Additional terminals create linked sessions with independent views
- Windows are shared, but each terminal can navigate independently
- Skipped in IDE terminals (VSCode, Emacs) and Warp

**Multiple terminals:**

```
Terminal 1: main   │ 1:zsh* 2:nvim  3:htop    ← viewing window 1
Terminal 2: main-1 │ 1:zsh  2:nvim* 3:htop    ← viewing window 2 (independent)
```

### Closing Views

| Action | How |
|--------|-----|
| Close terminal window | Just close it (linked session auto-cleans) |
| Detach (keep running) | `prefix + d` |
| Kill current pane | `prefix + x` |
| Kill current window | `prefix + &` |
| Kill entire session | `tmux kill-session -t main` |

## Plugins

| Plugin | Description |
|--------|-------------|
| tpm | Plugin manager |
| tmux-sensible | Sane defaults |
| tmux-yank | Enhanced clipboard |
| tmux-resurrect | Save/restore sessions |
| tmux-continuum | Auto-save sessions |
| tmux-fzf | Fuzzy finder integration |
| tmux-thumbs | Vim-like text selection hints |
| tmux-open | Open files/URLs from copy mode |

### Plugin Locations

```
~/.tmux/plugins/
├── tpm/
├── tmux-sensible/
├── tmux-yank/
├── tmux-resurrect/
├── tmux-continuum/
├── tmux-fzf/
├── tmux-thumbs/
└── tmux-open/
```

## Key Bindings

### General

| Keys | Action |
|------|--------|
| `Ctrl+b` | Prefix key |
| `prefix + r` | Reload config |
| `prefix + d` | Detach session |
| `prefix + s` | List sessions |
| `prefix + $` | Rename session |

### Windows

| Keys | Action |
|------|--------|
| `prefix + c` | New window (in current path) |
| `prefix + ,` | Rename window |
| `prefix + &` | Kill window |
| `prefix + n` | Next window |
| `prefix + p` | Previous window |
| `prefix + <number>` | Go to window N |
| `Shift + Left/Right` | Switch windows (no prefix) |

### Panes

| Keys | Action |
|------|--------|
| `prefix + \|` | Split vertical |
| `prefix + -` | Split horizontal |
| `prefix + x` | Kill pane |
| `prefix + z` | Toggle pane zoom |
| `prefix + h/j/k/l` | Navigate panes (vim style) |
| `prefix + H/J/K/L` | Resize panes |
| `Alt + arrows` | Switch panes (no prefix) |

### Copy Mode (vi style)

| Keys | Action |
|------|--------|
| `prefix + [` | Enter copy mode |
| `v` | Begin selection |
| `y` | Copy selection |
| `q` | Exit copy mode |
| Mouse drag | Select and copy |

### Plugins

| Keys | Action |
|------|--------|
| `prefix + I` | Install plugins |
| `prefix + U` | Update plugins |
| `prefix + Ctrl+s` | Save session (resurrect) |
| `prefix + Ctrl+r` | Restore session (resurrect) |
| `prefix + f` | FZF menu |
| `prefix + t` | Thumbs hints mode |

### Copy Mode (tmux-open)

| Keys | Action |
|------|--------|
| `o` | Open file/URL |
| `Ctrl+o` | Open in $EDITOR |
| `S` | Search in Google |

### Nested Sessions (SSH)

| Keys | Target |
|------|--------|
| `prefix + <key>` | Outer (local) tmux |
| `prefix + b <key>` | Inner (remote) tmux |

## Session Management

### Resurrect

Sessions saved to `~/.tmux/resurrect/`

**Restored automatically:**
- Window layouts
- Pane contents
- Working directories
- Running programs (see list below)

**Programs restored:**

| Category | Programs |
|----------|----------|
| Editors | vim, nvim (with sessions) |
| System | man, less, more, tail, top, htop, btop, watch |
| Remote | ssh, mosh |
| Databases | psql, mysql, sqlite3 |
| Dev tools | yarn, npm, pnpm, node, python, ipython, cargo, go, docker |
| Git | lazygit, git log, git diff |

### Continuum

- Auto-saves every 10 minutes
- Auto-restores on tmux start

## Terminal Compatibility

### Kitty

**File:** `~/.config/kitty/custom.conf`

```
allow_remote_control yes
listen_on unix:/tmp/kitty
shell_integration enabled
clipboard_control write-clipboard write-primary read-clipboard read-primary
```

### Warp / VS Code

Tmux auto-start is disabled in Warp and VS Code (detected via `$TERM_PROGRAM`). This prevents conflicts with Claude Code and other IDE terminals.

### SSH

- OSC 52 clipboard works through SSH tunnels
- Remote sessions use different status bar color (yellow/brown)
- Session named `ssh-<hostname>` for clarity

## Visual Indicators

### Local Session

```
┌─────────────────────────────────────────┐
│ main │ 1:zsh                │ 12:34 │   │  ← Cyan status
└─────────────────────────────────────────┘
```

### Remote Session (SSH)

```
┌─────────────────────────────────────────┐
│ ssh-server (remote) │ 1:zsh │ 12:34 │   │  ← Yellow status
└─────────────────────────────────────────┘
```

## FZF Integration

Press `prefix + f` for menu:

| Option | Action |
|--------|--------|
| session | Switch/create/kill sessions |
| window | Switch/swap/kill windows |
| pane | Switch/swap/kill panes |
| command | Run tmux commands |
| keybinding | Search keybindings |
| clipboard | Browse clipboard history |
| process | Search processes |

## Thumbs Mode

Press `prefix + t` to activate hint mode:
- Type hint letters to copy text
- `Shift + hint` to open in browser/app

Recognizes: URLs, file paths, git hashes, IPs, UUIDs, hex colors

## Common Tasks

### Create Named Session

```bash
tmux new -s myproject
```

### Attach to Session

```bash
tmux attach -t myproject
# or
tmux a -t myproject
```

### List Sessions

```bash
tmux ls
```

### Kill Session

```bash
tmux kill-session -t myproject
```

### Send Command to Session

```bash
tmux send-keys -t myproject "command" Enter
```

## Troubleshooting

### Colors Not Working

```bash
# Check terminal supports true color
echo $TERM

# Should be tmux-256color inside tmux
# If not, check terminfo:
infocmp tmux-256color
```

### Clipboard Not Working

```bash
# Check wl-copy is installed
which wl-copy

# Test OSC 52 (should copy to clipboard)
printf '\033]52;c;%s\a' "$(echo -n 'test' | base64)"
```

### Plugins Not Loading

```bash
# Reinstall plugins
~/.tmux/plugins/tpm/bin/install_plugins

# Or inside tmux: prefix + I
```

### Resurrect Not Restoring

```bash
# Check save directory
ls ~/.tmux/resurrect/

# Manual save
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh

# Check last symlink exists
ls -la ~/.tmux/resurrect/last
```

### Nested Tmux Issues

Use `prefix + b` to send prefix to inner tmux.

If accidentally nested:
```bash
# Check nesting level
echo $TMUX
```

## Configuration Reference

### Terminal Settings

```bash
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -ag terminal-overrides ",xterm-kitty:RGB"
```

### General Settings

```bash
set -g mouse on
set -g history-limit 50000
set -sg escape-time 0          # No vim delay
set -g base-index 1            # Windows start at 1
set -g renumber-windows on
set -g focus-events on
```

### Clipboard

```bash
set -g set-clipboard on        # OSC 52
set -s copy-command 'wl-copy'  # Wayland
```

## File Locations

| File | Purpose |
|------|---------|
| `~/.tmux.conf` | Main configuration |
| `~/.config/zshrc/01-tmux` | Auto-start script |
| `~/.tmux/plugins/` | TPM plugins |
| `~/.tmux/resurrect/` | Saved sessions |

## Quick Reference

```bash
# Start tmux
tmux

# New named session
tmux new -s name

# Attach
tmux a -t name

# List sessions
tmux ls

# Kill session
tmux kill-session -t name

# Reload config (inside tmux)
prefix + r

# Detach
prefix + d

# Split panes
prefix + |    # vertical
prefix + -    # horizontal

# Navigate panes
prefix + h/j/k/l

# New window
prefix + c

# Save session
prefix + Ctrl+s

# Restore session
prefix + Ctrl+r

# FZF menu
prefix + f

# Thumbs hints
prefix + t
```

## Related

- [07-SHELL](./07-SHELL.md) - Zsh configuration
- [../desktop/10-TERMINALS](../desktop/10-TERMINALS.md) - Kitty terminal
