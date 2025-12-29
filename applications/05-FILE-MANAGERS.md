# 05 - File Managers

GUI and TUI file manager configuration.

## Nautilus (Files)

GNOME file manager - default GUI file manager.

### Launch

```bash
nautilus

# Open specific directory
nautilus ~/Documents

# Or via keybinding
# Super + E
```

### Configuration

**Directory:** `~/.config/nautilus/`

Settings managed via dconf/gsettings.

### Key Settings

```bash
# Show hidden files
gsettings set org.gnome.nautilus.preferences show-hidden-files true

# Default view (list/grid)
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

# Sort folders first
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+H` | Toggle hidden files |
| `Ctrl+L` | Location bar |
| `Ctrl+T` | New tab |
| `Ctrl+W` | Close tab |
| `F2` | Rename |
| `Delete` | Move to trash |
| `Shift+Delete` | Delete permanently |

### Open Terminal Here

Right-click context menu includes "Open in Terminal".

## Superfile

Modern TUI file manager.

### Launch

```bash
superfile

# Or short alias
spf
```

### Configuration

**Directory:** `~/.config/superfile/`

```
~/.config/superfile/
├── config.toml       # Main configuration
├── hotkeys.toml      # Keybindings
└── theme/            # Custom themes
```

### config.toml

```toml
theme = 'catppuccin'
editor = ""                    # Uses $EDITOR
auto_check_update = true
cd_on_quit = false
default_open_file_preview = true
default_directory = "."
nerdfont = true
transparent_background = false
sidebar_width = 20
```

### Keybindings

| Key | Action |
|-----|--------|
| `j/k` | Navigate down/up |
| `h/l` | Parent/enter directory |
| `Enter` | Open file |
| `Space` | Select file |
| `d` | Delete |
| `y` | Copy |
| `p` | Paste |
| `r` | Rename |
| `/` | Search |
| `q` | Quit |
| `?` | Help |

### Features

- Dual-pane view
- File preview
- Nerdfont icons
- Vim-style navigation
- Theme support (Catppuccin configured)

## Ranger

Classic TUI file manager (available).

### Launch

```bash
ranger
```

### Configuration

**Directory:** `~/.config/ranger/`

```
~/.config/ranger/
├── rc.conf           # Settings
├── rifle.conf        # File associations
├── commands.py       # Custom commands
└── scope.sh          # File previews
```

### Navigation

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate |
| `gg` | Go to top |
| `G` | Go to bottom |
| `S` | Open shell |
| `q` | Quit |
| `zh` | Toggle hidden |

## Yazi

Fast TUI file manager (available).

### Launch

```bash
yazi
```

### Configuration

**Directory:** `~/.config/yazi/`

```
~/.config/yazi/
├── yazi.toml         # Main config
├── keymap.toml       # Keybindings
└── theme.toml        # Theme
```

### Custom Keybindings

**File:** `~/.config/yazi/keymap.toml`

```toml
[mgr]
prepend_keymap = [
    # Edit with sudo (Shift+E)
    { on = "E", run = '''shell 'sudo -E nvim "$@"' --block --confirm''', desc = "Edit with sudo" },
]
```

| Key | Action |
|-----|--------|
| `E` | Edit with sudo (preserves LazyVim config) |

### Features

- Async I/O
- Built-in preview
- Plugin support
- Image preview (in supported terminals)

## Comparison

| Feature | Nautilus | Superfile | Ranger | Yazi |
|---------|----------|-----------|--------|------|
| Type | GUI | TUI | TUI | TUI |
| Vim Keys | No | Yes | Yes | Yes |
| Preview | Yes | Yes | Yes | Yes |
| Dual Pane | No | Yes | No | No |
| Async | Yes | Yes | No | Yes |
| Config | dconf | TOML | Python | TOML |

## Default File Manager

### Set Default

```bash
# Set Nautilus as default
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# Check current default
xdg-mime query default inode/directory
```

### Hyprland Integration

File manager keybinding in Hyprland:

```bash
# Super + E opens file manager
bind = $mainMod, E, exec, nautilus
```

## Quick Reference

```bash
# GUI file managers
nautilus              # GNOME Files
thunar                # XFCE (if installed)

# TUI file managers
superfile             # Modern TUI
ranger                # Classic TUI
yazi                  # Fast async TUI

# Config locations
~/.config/nautilus/
~/.config/superfile/
~/.config/ranger/
~/.config/yazi/
```

## Related

- [07-SHELL](./07-SHELL.md) - Shell file operations
- [01-OVERVIEW](./01-OVERVIEW.md) - Default applications
