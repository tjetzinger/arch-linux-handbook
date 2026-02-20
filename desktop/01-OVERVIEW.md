# 01 - Overview

Niri scrollable-tiling Wayland compositor with acaibowlz/niri-setup dotfiles.

> **Migration note:** Hyprland + ML4W were removed on 2026-02-20. Archive at `~/backup/ml4w-hyprland-archive-20260220.tar.gz`. See [14-NIRI](./14-NIRI.md) for full configuration.

## Component Stack

| Component | Choice |
|-----------|--------|
| Compositor | Niri |
| Config | acaibowlz/niri-setup (symlinked) |
| Bar | Waybar |
| Launcher | Fuzzel |
| Notifications | Dunst |
| Lock Screen | swaylock-effects |
| Idle Daemon | swayidle |
| Wallpaper | swww + swaybg |
| Terminal | Alacritty |
| Dock | None |
| File Manager | Nautilus |
| Keyring | GNOME Keyring |
| Display Manager | SDDM (Sequoia theme) |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                       Niri                               │
│  ┌─────────────────────────────────────────────────────┐│
│  │                    Waybar                           ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │   Column    │  │   Column    │  │     Column      │ │
│  │   (Warp)    │  │  (Firefox)  │  │    (Nautilus)   │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
│                                                         │
│              ← infinite horizontal scroll →             │
└─────────────────────────────────────────────────────────┘

Supporting Services:
├── swayidle (idle management)
├── swww + swaybg (wallpaper)
├── dunst (notifications)
├── polkit-gnome (authentication)
├── xwayland-satellite (X11 compatibility)
└── wl-paste + cliphist (clipboard)
```

## Session Startup

On login via SDDM, Niri sources `spawn-at-startup.kdl`:

1. XDG portal setup
2. Polkit agent
3. Wallpaper (swww + swaybg)
4. Dunst notifications
5. swayidle
6. cliphist clipboard
7. xwayland-satellite
8. Waybar

## Key Directories

```
~/.config/niri-setup/     # Main config repo (symlinked)
├── niri/                 # Niri config (→ ~/.config/niri)
├── waybar/               # Waybar config (→ ~/.config/waybar)
├── dunst/                # Dunst config (→ ~/.config/dunst)
├── fuzzel/               # Fuzzel config (→ ~/.config/fuzzel)
├── wlogout/              # Wlogout config (→ ~/.config/wlogout)
├── alacritty/            # Alacritty config (→ ~/.config/alacritty)
├── scripts/              # Helper scripts (→ ~/.config/niri-scripts)
├── niriswitcher/         # Window switcher (→ ~/.config/niriswitcher)
└── wallpapers/           # Wallpaper files
```

## Quick Reference

```bash
# Validate config
niri validate

# Reload config
niri msg action load-config-file

# List outputs
niri msg outputs

# Restart Waybar
pkill waybar; waybar &
```

## Related

- [14-NIRI](./14-NIRI.md) - Full Niri configuration and keybindings
- [15-SDDM](./15-SDDM.md) - Display manager
