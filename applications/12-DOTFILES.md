# 12 - Dotfiles

Dotfiles structure and management.

## Overview

Configuration files are managed through a dotfiles repository with symlinks.

| Component | Location |
|-----------|----------|
| Repository | `~/dotfiles/` |
| Target | `~/.config/` |
| Backup | `~/.ml4w-hyprland/backup/` |

## Repository Structure

**Directory:** `~/dotfiles/`

```
~/dotfiles/
└── .config/
    ├── ags/              # AGS shell
    ├── bashrc/           # Bash config
    ├── dunst/            # Notifications
    ├── fastfetch/        # System info
    ├── gtk-3.0/          # GTK3 theme
    ├── gtk-4.0/          # GTK4 theme
    ├── hypr/             # Hyprland
    ├── kitty/            # Terminal
    ├── matugen/          # Material colors
    ├── ml4w/             # ML4W scripts
    ├── nvim/             # Neovim
    ├── nwg-dock-hyprland/
    ├── ohmyposh/         # Shell prompt
    ├── qt6ct/            # Qt6 theme
    ├── rofi/             # Launcher
    ├── swaync/           # Notifications
    ├── vim/              # Vim
    ├── wal/              # Pywal
    ├── waybar/           # Status bar
    ├── waypaper/         # Wallpaper
    ├── wlogout/          # Logout menu
    ├── xsettingsd/       # X settings
    └── zshrc/            # Zsh config
```

## Symlinks

Configurations are symlinked from dotfiles to `~/.config/`:

```bash
# Example symlinks
~/.config/nvim -> ~/dotfiles/.config/nvim
~/.config/hypr -> ~/dotfiles/.config/hypr
~/.config/kitty -> ~/dotfiles/.config/kitty
~/.config/zshrc -> ~/dotfiles/.config/zshrc
```

### View Symlinks

```bash
# List all symlinks in .config
ls -la ~/.config/ | grep "^l"

# Check specific symlink
ls -la ~/.config/nvim
```

## Symlinked vs Local

### Symlinked (from dotfiles)

- ags
- bashrc
- dunst
- fastfetch
- gtk-3.0, gtk-4.0
- hypr
- kitty
- matugen
- ml4w
- nvim, vim
- nwg-dock-hyprland
- ohmyposh
- qt6ct
- rofi
- swaync
- wal
- waybar
- waypaper
- wlogout
- xsettingsd
- zshrc

### Local (not symlinked)

- google-chrome/
- Code/
- vlc/
- btop/
- superfile/
- warp-terminal/
- And others with user-specific data

## Backup Location

**Directory:** `~/.ml4w-hyprland/backup/`

Contains backup copies of dotfiles made during ML4W updates:

```
~/.ml4w-hyprland/backup/
├── dotfiles/
│   └── .config/
│       └── nvim/       # Full Lua neovim config
└── ...
```

## Managing Dotfiles

### Add New Configuration

1. Move config to dotfiles:
   ```bash
   mv ~/.config/newapp ~/dotfiles/.config/newapp
   ```

2. Create symlink:
   ```bash
   ln -s ~/dotfiles/.config/newapp ~/.config/newapp
   ```

3. Verify:
   ```bash
   ls -la ~/.config/newapp
   ```

### Update Dotfiles

Changes in `~/.config/` automatically apply to `~/dotfiles/` due to symlinks.

### Remove Symlink

```bash
# Remove symlink (keeps dotfiles)
rm ~/.config/appname

# Copy back if needed
cp -r ~/dotfiles/.config/appname ~/.config/
```

## Version Control

### Initialize Git

```bash
cd ~/dotfiles
git init
git add .
git commit -m "Initial dotfiles"
```

### Push to GitHub

```bash
# Create repo on GitHub first
gh repo create dotfiles --private

# Push
git remote add origin git@github.com:username/dotfiles.git
git push -u origin main
```

### Clone on New System

```bash
git clone git@github.com:username/dotfiles.git ~/dotfiles

# Create symlinks
ln -s ~/dotfiles/.config/nvim ~/.config/nvim
# ... repeat for each config
```

## Home Directory Dotfiles

Some configs live directly in home:

| File | Purpose |
|------|---------|
| `~/.gitconfig` | Git configuration |
| `~/.tmux.conf` | tmux configuration |
| `~/.zshrc` | Zsh loader |
| `~/.bashrc` | Bash loader |
| `~/.ssh/config` | SSH configuration |

### Symlink Home Dotfiles

```bash
# Add to dotfiles repo
mv ~/.gitconfig ~/dotfiles/
ln -s ~/dotfiles/.gitconfig ~/.gitconfig
```

## ML4W Framework

ML4W manages many dotfiles through its installer and updater:

```bash
# Update ML4W
ml4w-update

# Or
~/.config/ml4w/update.sh
```

### ML4W Paths

| Path | Purpose |
|------|---------|
| `~/.config/ml4w/` | ML4W configuration |
| `~/.config/ml4w/scripts/` | Custom scripts |
| `~/.config/ml4w/settings/` | Settings files |
| `~/.ml4w-hyprland/` | ML4W data |

## Stow Alternative

GNU Stow is a popular dotfiles manager:

```bash
# Install
sudo pacman -S stow

# Structure
~/dotfiles/
├── nvim/
│   └── .config/
│       └── nvim/
├── zsh/
│   └── .zshrc
└── git/
    └── .gitconfig

# Deploy
cd ~/dotfiles
stow nvim    # Creates ~/.config/nvim symlink
stow zsh     # Creates ~/.zshrc symlink
stow git     # Creates ~/.gitconfig symlink
```

## Best Practices

### What to Include

- Shell configuration
- Editor configuration
- Window manager config
- Theme settings
- Git configuration

### What to Exclude

- Secrets/credentials
- Application cache
- User-specific paths
- Large binary files

### .gitignore Example

```gitignore
# Secrets
*.secret
credentials.json
.env

# Cache
**/Cache/
**/cache/

# Logs
*.log

# OS files
.DS_Store
Thumbs.db
```

## Quick Reference

```bash
# View symlinks
ls -la ~/.config/ | grep "^l"

# Create symlink
ln -s ~/dotfiles/.config/app ~/.config/app

# Remove symlink
rm ~/.config/app

# Dotfiles repo
cd ~/dotfiles
git status
git add .
git commit -m "Update config"
git push

# Locations
~/dotfiles/                      # Repository
~/.config/                       # Symlink target
~/.ml4w-hyprland/backup/         # Backups
```

## Related

- [07-SHELL](./07-SHELL.md) - Shell configuration
- [03-NEOVIM](./03-NEOVIM.md) - Editor configuration
- [../desktop/](../desktop/) - Desktop configuration
