# 01 - Application Overview

Inventory of installed applications and their configuration locations.

## Application Categories

### Development

| Application | Command | Config Location |
|-------------|---------|-----------------|
| Neovim | `nvim` | `~/.config/nvim/` |
| VS Code | `code` | `~/.config/Code/User/` |
| Git | `git` | `~/.gitconfig` |
| GitHub CLI | `gh` | `~/.config/gh/` |

### Terminals & Shell

| Application | Command | Config Location |
|-------------|---------|-----------------|
| Warp | `warp-terminal` | `~/.config/warp-terminal/` |
| Kitty | `kitty` | `~/.config/kitty/` |
| Zsh | `zsh` | `~/.config/zshrc/` |
| tmux | `tmux` | `~/.tmux.conf` |

### Browsers

| Application | Command | Config Location |
|-------------|---------|-----------------|
| Google Chrome | `google-chrome-stable` | `~/.config/google-chrome/` |
| Firefox | `firefox` (flatpak) | `~/.var/app/org.mozilla.firefox/` |

### File Managers

| Application | Command | Config Location |
|-------------|---------|-----------------|
| Nautilus | `nautilus` | `~/.config/nautilus/` |
| Superfile | `superfile` | `~/.config/superfile/` |
| Ranger | `ranger` | `~/.config/ranger/` |
| Yazi | `yazi` | `~/.config/yazi/` |

### Media

| Application | Command | Config Location |
|-------------|---------|-----------------|
| VLC | `vlc` | `~/.config/vlc/` |
| mpv | `mpv` | `~/.config/mpv/` |
| GIMP | `gimp` | `~/.config/GIMP/` |
| yt-dlp | `yt-dlp` | `~/.config/yt-dlp/` |

### Office

| Application | Command | Config Location |
|-------------|---------|-----------------|
| LibreOffice | `libreoffice` | `~/.config/libreoffice/` |
| GNOME Text Editor | `gnome-text-editor` | Standard |

### System Tools

| Application | Command | Config Location |
|-------------|---------|-----------------|
| btop | `btop` | `~/.config/btop/` |
| htop | `htop` | `~/.config/htop/` |
| fastfetch | `fastfetch` | `~/.config/fastfetch/` |

### AI Tools

| Application | Command | Config Location |
|-------------|---------|-----------------|
| Claude CLI | `claude` | `~/.claude/` |
| ChatBox | GUI | `~/.config/xyz.chatboxapp.app/` |

### Remote Access

| Application | Command | Config Location |
|-------------|---------|-----------------|
| Remmina | `remmina` | `~/.config/remmina/` |
| Virt-Manager | `virt-manager` | Standard |
| Virt-Viewer | `virt-viewer` | `~/.config/virt-viewer/` |

### Virtualization

| Application | Command | Config Location |
|-------------|---------|-----------------|
| QEMU | `qemu-system-x86_64` | N/A |
| libvirt | `virsh` | `/etc/libvirt/` |

## Default Applications

**File:** `~/.config/mimeapps.list`

| MIME Type | Application |
|-----------|-------------|
| HTML/HTTP/HTTPS | Google Chrome |
| PDF | Google Chrome |
| Plain text | GNOME Text Editor |
| Synology files | Synology Drive |

### View Defaults

```bash
xdg-mime query default text/html
xdg-mime query default application/pdf
```

### Set Defaults

```bash
xdg-mime default google-chrome.desktop text/html
xdg-mime default org.gnome.TextEditor.desktop text/plain
```

## Config Location Patterns

### Standard XDG Locations

```
~/.config/           # User configuration
~/.local/share/      # User data
~/.local/bin/        # User executables
~/.cache/            # Cached data
```

### Dotfiles Symlinks

Most configurations are symlinked from `~/dotfiles/.config/`:

```bash
ls -la ~/.config/ | grep dotfiles
```

Symlinked applications include:
- nvim, vim
- kitty
- zshrc, bashrc
- hypr (Hyprland)
- waybar, rofi, swaync
- gtk-3.0, gtk-4.0
- ohmyposh
- fastfetch

## Installed Package Count

```bash
# Explicitly installed packages
pacman -Qe | wc -l

# All installed packages
pacman -Q | wc -l

# AUR packages
pacman -Qm | wc -l

# Flatpak applications
flatpak list | wc -l
```

## Desktop Applications

Desktop entries are stored in:

```bash
/usr/share/applications/      # System-wide
~/.local/share/applications/  # User-specific
```

### List All Desktop Apps

```bash
ls /usr/share/applications/*.desktop | wc -l
```

## Quick Reference

```bash
# Find config for an app
ls ~/.config/ | grep <app>

# Find app binary
which <app>

# Check if installed
pacman -Qs <app>

# App info
pacman -Qi <app>

# List files owned by package
pacman -Ql <package>
```

## Related

- [02-BROWSERS](./02-BROWSERS.md) - Browser configuration
- [03-NEOVIM](./03-NEOVIM.md) - Editor configuration
- [12-DOTFILES](./12-DOTFILES.md) - Dotfiles management
