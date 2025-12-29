# Applications

Installed applications and their configurations.

## Contents

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | Application inventory and config locations |
| [02-BROWSERS](./02-BROWSERS.md) | Chrome (primary), Firefox |
| [03-NEOVIM](./03-NEOVIM.md) | Neovim with 52 plugins |
| [04-EDITORS](./04-EDITORS.md) | VS Code |
| [05-FILE-MANAGERS](./05-FILE-MANAGERS.md) | Nautilus, Superfile |
| [06-MEDIA](./06-MEDIA.md) | VLC, mpv, GIMP, yt-dlp |
| [07-SHELL](./07-SHELL.md) | Zsh, oh-my-zsh, oh-my-posh |
| [08-GIT-SSH](./08-GIT-SSH.md) | Git, GitHub CLI, SSH profiles |
| [09-DEV-TOOLS](./09-DEV-TOOLS.md) | Python, Node.js, Rust, Go |
| [10-AI-TOOLS](./10-AI-TOOLS.md) | Claude CLI, ChatBox, MCP, Ollama |
| [11-REMOTE](./11-REMOTE.md) | Remmina, remote access |
| [12-DOTFILES](./12-DOTFILES.md) | Dotfiles structure and management |
| [13-ANDROID](./13-ANDROID.md) | Waydroid Android container |
| [14-TMUX](./14-TMUX.md) | Tmux multiplexer with persistence |

## Quick Reference

```bash
# Editors
nvim                              # Neovim
code                              # VS Code

# File managers
nautilus                          # GUI file manager
superfile                         # TUI file manager

# Media
mpv <file>                        # Media player
yt-dlp <url>                      # YouTube download

# Shell
$EDITOR ~/.config/zshrc/25-aliases  # Edit aliases
source ~/.zshrc                     # Reload shell config

# Tmux
tmux                              # Start/attach session
tmux new -s name                  # New named session
tmux a -t name                    # Attach to session
# prefix + f                      # FZF menu
# prefix + Ctrl+s                 # Save session

# Git
gh repo view --web               # Open repo in browser
gh pr create                     # Create pull request

# AI Tools
claude                           # Claude Code CLI

# Android (Waydroid)
waydroid show-full-ui            # Launch Android
waydroid app list                # List Android apps
waydroid session start/stop      # Manage session
```

## Config Locations

| Application | Configuration |
|-------------|---------------|
| Neovim | `~/.config/nvim/` |
| VS Code | `~/.config/Code/User/` |
| Zsh | `~/.config/zshrc/` |
| Tmux | `~/.tmux.conf`, `~/.tmux/` |
| Git | `~/.gitconfig` |
| SSH | `~/.ssh/config` |
| mpv | `~/.config/mpv/` |
| Dotfiles | `~/dotfiles/` |

## Dotfiles

Most configurations are symlinked from `~/dotfiles/.config/` for version control.

## Related

- [../desktop/](../desktop/) - Hyprland desktop environment
- [../systemd/](../systemd/) - System services
