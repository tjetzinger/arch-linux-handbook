# 07 - Desktop Environment (Hyprland)

Install Hyprland using the ML4W (My Linux For Work) setup.

## Overview

We'll use [ML4W Hyprland](https://github.com/mylinuxforwork/dotfiles) which provides:
- Pre-configured Hyprland setup
- Waybar, Rofi, and other utilities
- Theming and customization tools
- Easy installation and updates

---

## Step 1: Prerequisites

### Install Dependencies

```bash
sudo pacman -S --needed \
    git \
    base-devel \
    xdg-user-dirs \
    xdg-utils \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    polkit-gnome
```

### Create User Directories

```bash
xdg-user-dirs-update
```

### Enable PipeWire (Audio)

```bash
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber
```

---

## Step 2: Install Hyprland

### Core Hyprland

```bash
sudo pacman -S hyprland
```

### Essential Wayland Tools

```bash
sudo pacman -S \
    xorg-xwayland \
    qt5-wayland \
    qt6-wayland \
    wl-clipboard \
    cliphist
```

---

## Step 3: Install ML4W Hyprland

### Using yay (AUR)

```bash
yay -S ml4w-hyprland
```

### Run Setup

```bash
ml4w-hyprland-setup
```

The setup wizard will guide you through:
- Package installation
- Dotfiles configuration
- Theme selection
- Monitor configuration

---

## Step 4: Essential Applications

### Terminal Emulator

```bash
sudo pacman -S alacritty  # or kitty, wezterm
```

### File Manager

```bash
sudo pacman -S \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    gvfs \
    tumbler \
    ffmpegthumbnailer
```

### Web Browser

```bash
yay -S google-chrome
# or
sudo pacman -S firefox
```

### Application Launcher

```bash
sudo pacman -S wofi  # or rofi-wayland
```

### Screenshot Tools

```bash
sudo pacman -S \
    grim \
    slurp \
    swappy
```

### Notification Daemon

```bash
sudo pacman -S mako  # or dunst
```

### Screen Lock

```bash
sudo pacman -S swaylock
```

---

## Step 5: Display Manager (Optional)

You can start Hyprland from TTY or use a display manager.

### Start from TTY (Recommended)

Add to `~/.bash_profile` or `~/.zprofile`:

```bash
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi
```

### Using SDDM (Alternative)

```bash
sudo pacman -S sddm
sudo systemctl enable sddm
```

---

## Step 6: Additional Packages

### Fonts

```bash
sudo pacman -S \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji
```

### Multimedia

```bash
sudo pacman -S \
    mpv \
    imv \
    zathura \
    zathura-pdf-mupdf
```

### System Utilities

```bash
sudo pacman -S \
    brightnessctl \
    playerctl \
    pamixer \
    pavucontrol \
    nm-connection-editor \
    blueman \
    gnome-keyring
```

### Development

```bash
sudo pacman -S \
    neovim \
    tmux \
    fzf \
    ripgrep \
    fd \
    bat \
    eza \
    lazygit
```

---

## Step 7: Basic Hyprland Configuration

ML4W handles most configuration, but you can customize:

### Config Location

```bash
~/.config/hypr/hyprland.conf
```

### Essential Settings

```ini
# Monitor configuration
monitor=,preferred,auto,1

# Keyboard layout
input {
    kb_layout = de
    kb_variant =
    kb_options = caps:escape
}

# Autostart
exec-once = waybar
exec-once = nm-applet
exec-once = blueman-applet
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
```

---

## Step 8: Environment Variables

Create `~/.config/hypr/env.conf`:

```ini
# Qt
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1

# GTK
env = GDK_BACKEND,wayland,x11

# Toolkit
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland

# XDG
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# Cursor
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Bibata-Modern-Classic
```

Include in main config:
```ini
source = ~/.config/hypr/env.conf
```

---

## Step 9: Theming

### GTK Theme

```bash
sudo pacman -S gnome-themes-extra adwaita-icon-theme

# Install popular themes
yay -S catppuccin-gtk-theme-mocha papirus-icon-theme
```

### Configure

```bash
# Using nwg-look (recommended)
sudo pacman -S nwg-look
nwg-look

# Or manually in ~/.config/gtk-3.0/settings.ini
```

### Cursor Theme

```bash
yay -S bibata-cursor-theme-bin
```

Set in Hyprland config:
```ini
env = XCURSOR_THEME,Bibata-Modern-Classic
env = XCURSOR_SIZE,24
```

---

## Step 10: First Login

1. Logout or reboot
2. At TTY or display manager, start Hyprland
3. Press `SUPER + RETURN` to open terminal
4. Use `SUPER + D` for app launcher

### Default Keybinds (ML4W)

| Key | Action |
|-----|--------|
| `SUPER + RETURN` | Terminal |
| `SUPER + D` | App launcher |
| `SUPER + Q` | Close window |
| `SUPER + M` | Exit Hyprland |
| `SUPER + 1-9` | Switch workspace |
| `SUPER + SHIFT + 1-9` | Move to workspace |

---

## Troubleshooting

### Black Screen
```bash
# Check Hyprland log
cat ~/.local/share/hyprland/hyprland.log
```

### No Cursor
```bash
# Ensure cursor theme is installed
ls /usr/share/icons/

# Check env variables
echo $XCURSOR_THEME
```

### Audio Not Working
```bash
# Check PipeWire
systemctl --user status pipewire wireplumber

# Restart
systemctl --user restart pipewire wireplumber
```

### Screen Sharing (OBS, Discord)
```bash
sudo pacman -S xdg-desktop-portal-hyprland
```

---

## Quick Reference

```bash
# Core packages
sudo pacman -S hyprland xorg-xwayland qt5-wayland qt6-wayland

# ML4W
yay -S ml4w-hyprland
ml4w-hyprland-setup

# Essential apps
sudo pacman -S alacritty thunar firefox

# Fonts
sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts-emoji

# Auto-start on login (add to ~/.zprofile)
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi
```

---

## Next Step

Proceed to [08-POST-INSTALL.md](./08-POST-INSTALL.md) for final configuration and optimizations.
