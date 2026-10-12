# 12 - Dotfiles

Dotfiles structure and management.

## Overview

Desktop configs come from the **niri-setup** repository, symlinked into `~/.config/`. System configs (logind, TLP, WirePlumber) are kept as copies in this handbook under [dotfiles/](../dotfiles/).

| Component | Location |
|-----------|----------|
| Desktop repo | `~/.config/niri-setup/` (fork of acaibowlz/niri-setup, remote `github.com/youruser/niri-setup`) |
| Target | `~/.config/` (symlinks) |
| System config copies | `~/Workspace/arch-linux-guides/dotfiles/system/` |
| Backup | Borg (`/home/tt` daily), see [system-recovery/07](../system-recovery/07-BORG-BACKUP-AUTOMATION.md) |

The ML4W `~/dotfiles/` repo is gone since the switch to Niri on 2026-02-20. `~/.ml4w-hyprland/` is an empty leftover.

## Repository Structure

**Directory:** `~/.config/niri-setup/`

```
~/.config/niri-setup/
├── alacritty/      # Terminal
├── dunst/          # Notifications
├── fuzzel/         # Launcher
├── niri/           # Compositor (config.kdl + included *.kdl files)
├── niriswitcher/   # Window switcher
├── scripts/        # swayidle, swaylock, wallpaper, power profile helpers
├── wallpapers/
├── waybar/         # Status bar
├── wlogout/        # Logout menu
└── setup.sh        # Package install + $NIRICONF path substitution
```

## Symlinks

```
~/.config/niri          -> ~/.config/niri-setup/niri
~/.config/niri-scripts  -> ~/.config/niri-setup/scripts
~/.config/waybar        -> ~/.config/niri-setup/waybar
~/.config/dunst         -> ~/.config/niri-setup/dunst
~/.config/fuzzel        -> ~/.config/niri-setup/fuzzel
~/.config/wlogout       -> ~/.config/niri-setup/wlogout
~/.config/niriswitcher  -> ~/.config/niri-setup/niriswitcher
~/.config/alacritty     -> ~/.config/niri-setup/alacritty
```

`~/.config/google-chrome` is also a symlink, but to `/run/user/1000/psd/…` (profile-sync-daemon keeps the profile in RAM).

### View Symlinks

```bash
find ~/.config -maxdepth 1 -type l -printf '%f -> %l\n'
```

## Symlinked vs Local

- **Symlinked:** the niri-setup folders above.
- **Local, not in a repo:** everything else in `~/.config/` (nvim, kitty, btop, Code, …) and the home files below. Borg backs them up.

## Managing Dotfiles

### Add New Configuration

1. Move config into the repo:
   ```bash
   mv ~/.config/newapp ~/.config/niri-setup/newapp
   ```

2. Create symlink:
   ```bash
   ln -s ~/.config/niri-setup/newapp ~/.config/newapp
   ```

3. Verify:
   ```bash
   ls -la ~/.config/newapp
   ```

### Update Dotfiles

Edits in `~/.config/<app>` land in `~/.config/niri-setup/` through the symlinks. Commit and push them from there.

### Remove Symlink

```bash
# Remove symlink (keeps dotfiles)
rm ~/.config/appname

# Copy back if needed
cp -r ~/.config/niri-setup/appname ~/.config/
```

## Version Control

```bash
cd ~/.config/niri-setup
git status
git add -A && git commit -m "Update config"
git push
```

### Clone on New System

```bash
git clone https://github.com/youruser/niri-setup ~/.config/niri-setup
cd ~/.config/niri-setup
./setup.sh          # installs packages, fills in $NIRICONF paths, links niri/config.kdl
# then create the remaining symlinks (see Symlinks above)
niri validate
```

`setup.sh` only links `niri/config.kdl`; the folder symlinks listed above were created by hand.

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
mv ~/.gitconfig ~/.config/niri-setup/home/.gitconfig
ln -s ~/.config/niri-setup/home/.gitconfig ~/.gitconfig
```

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
ln -s ~/.config/niri-setup/app ~/.config/app

# Remove symlink
rm ~/.config/app

# Desktop config repo
cd ~/.config/niri-setup
git status
git add .
git commit -m "Update config"
git push

# Locations
~/.config/niri-setup/            # Repository
~/.config/                       # Symlink target
```

## Related

- [07-SHELL](./07-SHELL.md) - Shell configuration
- [03-NEOVIM](./03-NEOVIM.md) - Editor configuration
- [../desktop/](../desktop/) - Desktop configuration
