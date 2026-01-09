# Niri Compositor

Niri is a scrollable-tiling Wayland compositor that can be installed alongside Hyprland.

## Overview

Unlike traditional tiling (Hyprland, Sway), Niri arranges windows in columns on an infinite horizontal strip. Scroll left/right to navigate.

| Feature | Description |
|---------|-------------|
| Layout | Infinite horizontal scroll |
| Workspaces | Dynamic, vertical (GNOME-style) |
| Per-monitor | Each monitor has isolated workspaces |
| Floating | Supported since v25.01 |
| XWayland | Via xwayland-satellite |

## Installation

Niri installs alongside Hyprland without conflicts.

```bash
# Core + essentials
sudo pacman -S niri swaylock swayidle xwayland-satellite swaybg fuzzel
```

### Installed Packages

| Package | Purpose |
|---------|---------|
| `niri` | Compositor |
| `swaylock` | Screen locker |
| `swayidle` | Idle management |
| `xwayland-satellite` | X11 app support |
| `swaybg` | Wallpaper |
| `fuzzel` | App launcher (Wayland-native) |

### Shared with Hyprland

These work in both compositors:
- `waybar` (needs niri-specific modules)
- `rofi`
- `kitty`
- `swaync`
- `xdg-desktop-portal-gtk`

## Starting Niri

1. Logout from Hyprland
2. At SDDM login, select "Niri" session
3. Login

Session files:
- `/usr/share/wayland-sessions/niri.desktop`
- `/usr/share/wayland-sessions/hyprland.desktop`

## Configuration

Config location: `~/.config/niri/config.kdl`

```bash
# Copy default config
mkdir -p ~/.config/niri
cp /usr/share/doc/niri/default-config.kdl ~/.config/niri/config.kdl
```

Config uses KDL format (not TOML like Hyprland). Live-reloads on save.

### Key Sections

| Section | Purpose |
|---------|---------|
| `input {}` | Keyboard, mouse, touchpad |
| `output "name" {}` | Monitor configuration |
| `layout {}` | Gaps, borders, widths |
| `binds {}` | Keybindings |
| `spawn-at-startup` | Autostart programs |
| `window-rule {}` | Per-app rules |

### Example: Change Terminal

```kdl
binds {
    Mod+T { spawn "kitty"; }
}
```

### Example: Autostart

```kdl
spawn-at-startup "waybar"
spawn-at-startup "swaybg" "-i" "/path/to/wallpaper.jpg"
spawn-at-startup "swaync"
```

## Keybindings

`Mod` = Super key (when running from SDDM)

### Essential

| Key | Action |
|-----|--------|
| `Mod+Shift+/` | Show hotkey overlay |
| `Mod+T` | Terminal |
| `Mod+D` | App launcher (fuzzel) |
| `Mod+Q` | Close window |
| `Mod+Shift+E` | Quit Niri |
| `Super+Alt+L` | Lock screen |

### Navigation (Vim-style)

| Key | Action |
|-----|--------|
| `Mod+H/J/K/L` | Focus left/down/up/right |
| `Mod+Ctrl+H/J/K/L` | Move window |
| `Mod+Shift+H/J/K/L` | Focus monitor |

### Workspaces

| Key | Action |
|-----|--------|
| `Mod+1-9` | Focus workspace |
| `Mod+Ctrl+1-9` | Move to workspace |
| `Mod+U/I` | Focus workspace down/up |
| `Mod+O` | Toggle Overview |

### Window Layout

| Key | Action |
|-----|--------|
| `Mod+F` | Maximize column |
| `Mod+Shift+F` | Fullscreen |
| `Mod+C` | Center column |
| `Mod+V` | Toggle floating |
| `Mod+W` | Toggle tabbed column |
| `Mod+R` | Cycle column widths |
| `Mod+-/=` | Adjust width ±10% |

### Column Stacking

| Key | Action |
|-----|--------|
| `Mod+[` | Consume/expel window left |
| `Mod+]` | Consume/expel window right |
| `Mod+,` | Consume into column |
| `Mod+.` | Expel from column |

## Waybar Configuration

Niri requires different modules than Hyprland:

| Hyprland Module | Niri Module |
|-----------------|-------------|
| `hyprland/workspaces` | `niri/workspaces` |
| `hyprland/window` | `niri/window` |
| `hyprland/language` | `niri/language` |

Generic modules work unchanged: `clock`, `battery`, `network`, `pulseaudio`, `tray`, etc.

## Comparison with Hyprland

| Aspect | Hyprland | Niri |
|--------|----------|------|
| Layout paradigm | Traditional tiling | Scrollable columns |
| Config format | TOML-like | KDL |
| Screen locker | hyprlock | swaylock |
| Idle daemon | hypridle | swayidle |
| Wallpaper | hyprpaper/swww | swaybg |
| Plugins | Yes | No |
| IPC | hyprctl | niri msg |

## IPC Commands

```bash
# List outputs
niri msg outputs

# Focus workspace
niri msg action focus-workspace 1

# Take screenshot
niri msg action screenshot

# Power off monitors
niri msg action power-off-monitors
```

## Switching Between Compositors

Both sessions remain available at SDDM. Configs are separate:
- Hyprland: `~/.config/hypr/`
- Niri: `~/.config/niri/`

No restart required to switch - just logout and select different session.

## Troubleshooting

### X11 Apps Not Working

Ensure xwayland-satellite is running:
```bash
# Add to config
spawn-at-startup "xwayland-satellite"
```

### Validate Config

```bash
niri validate
```

### Check Logs

```bash
journalctl --user -u niri -f
```

## Resources

- [Niri GitHub](https://github.com/YaLTeR/niri)
- [Official Documentation](https://yalter.github.io/niri/)
- [ArchWiki](https://wiki.archlinux.org/title/Niri)
- [Matrix Chat](https://matrix.to/#/#niri:matrix.org)
