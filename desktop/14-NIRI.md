# Niri Compositor

Niri is a scrollable-tiling Wayland compositor using the acaibowlz/niri-setup dotfiles.

## Overview

Unlike traditional tiling (Hyprland, Sway), Niri arranges windows in columns on an infinite horizontal strip. Scroll left/right to navigate.

| Feature | Description |
|---------|-------------|
| Layout | Infinite horizontal scroll |
| Workspaces | Dynamic, vertical (GNOME-style) |
| Per-monitor | Each monitor has isolated workspaces |
| Floating | Supported since v25.01 |
| XWayland | Via xwayland-satellite |

## Installation (acaibowlz/niri-setup)

Using symlinked configuration from acaibowlz/niri-setup repository.

```bash
# Clone to permanent location
git clone https://github.com/acaibowlz/niri-setup.git ~/.config/niri-setup

# Install packages
yay -S --needed niri waybar fuzzel dunst swaylock-effects swww wlogout \
  brightnessctl cliphist pamixer pwvucontrol swaybg swayidle \
  power-profiles-daemon polkit-gnome xwayland-satellite niriswitcher alacritty

# Create symlinks
ln -s ~/.config/niri-setup/niri ~/.config/niri
ln -s ~/.config/niri-setup/waybar ~/.config/waybar
ln -s ~/.config/niri-setup/dunst ~/.config/dunst
ln -s ~/.config/niri-setup/fuzzel ~/.config/fuzzel
ln -s ~/.config/niri-setup/wlogout ~/.config/wlogout
ln -s ~/.config/niri-setup/alacritty ~/.config/alacritty
ln -s ~/.config/niri-setup/scripts ~/.config/niri-scripts
ln -s ~/.config/niri-setup/niriswitcher ~/.config/niriswitcher
```

### Environment Variable

The config uses `$NIRICONF` variable. Add to `~/.config/environment.d/niriconf.conf`:

```bash
NIRICONF=/home/tt/.config/niri-setup
```

Also add to `~/.config/fish/config.fish`:
```fish
set -gx NIRICONF "$HOME/.config/niri-setup"
```

## Configuration Structure

Config location: `~/.config/niri-setup/niri/`

| File | Purpose |
|------|---------|
| `config.kdl` | Main config (includes others) |
| `input.kdl` | Keyboard, mouse, touchpad |
| `outputs.kdl` | Monitor configuration |
| `layout.kdl` | Gaps, borders, widths |
| `binds.kdl` | Keybindings |
| `spawn-at-startup.kdl` | Autostart programs |
| `wallpapers.kdl` | Wallpaper configuration |
| `rules.kdl` | Per-app window rules |
| `misc.kdl` | Screenshots, hotkey overlay |

### Input Configuration

```kdl
input {
    keyboard {
        xkb {
            layout "de"
            variant "nodeadkeys"
            options "caps:escape"
        }
    }
    touchpad {
        tap
        natural-scroll
    }
    focus-follows-mouse
}
```

### Layout Configuration

| Setting | Value |
|---------|-------|
| Gaps | 7px |
| Focus ring | 1px orange (#FF8C00) |
| Default width | 50% |
| Presets | 33%, 50%, 67%, 100% |

## Keybindings

`Mod` = Super key

### Applications

| Key | Action |
|-----|--------|
| `Mod+Return` | Alacritty terminal |
| `Mod+Space` | Fuzzel launcher |
| `Mod+B` | Google Chrome |
| `Mod+E` | Nautilus file manager |
| `Mod+L` | Lock screen (swaylock) |
| `Mod+C` | Clipboard history |
| `Mod+I` | Change idle time |
| `Mod+P` | Change power profile |
| `Mod+U` | System updater |
| `Mod+W` | Toggle waybar |
| `Mod+Ctrl+W` | Wallpaper selector |
| `Mod+Backspace` | Logout menu (wlogout) |

### Media Keys

| Key | Action |
|-----|--------|
| Brightness Up/Down | Adjust brightness ±5% |
| Volume Up/Down | Adjust volume ±5% |
| Mute | Toggle speaker mute |
| Mic Mute (Fn+F4) | Toggle mic mute |
| Play/Pause/Next/Prev | Media controls |

### Windows

| Key | Action |
|-----|--------|
| `Mod+Q` | Close window |
| `Mod+T` | Toggle floating |
| `Mod+M` | Maximize column |
| `Mod+F` | Fullscreen |
| `Mod+Arrow` | Focus direction |
| `Mod+Ctrl+Arrow` | Move window |
| `Mod+Shift+Arrow` | Resize ±10% |
| `Mod+Home/End` | Focus first/last column |
| `Mod+[ / ]` | Consume/expel window |
| `Mod+, / .` | Stack/unstack window |
| `Mod+Ctrl+C` | Center column |
| `Mod+R` | Cycle preset widths |

### Workspaces

| Key | Action |
|-----|--------|
| `Mod+1-9` | Focus workspace 1-9 |
| `Mod+Ctrl+1-9` | Move to workspace 1-9 |
| `Mod+Page Up/Down` | Switch workspace |
| `Mod+Ctrl+Page Up/Down` | Move to workspace |
| `Mod+A` | Overview |

### Screenshots

| Key | Action |
|-----|--------|
| `Print` | Screenshot screen |
| `Ctrl+Print` | Screenshot window |
| `Shift+Print` | Screenshot select area |

### Help

| Key | Action |
|-----|--------|
| `Mod+Shift+ß` | Hotkey overlay |

## Waybar

Waybar config: `~/.config/niri-setup/waybar/`

### Click Actions

| Module | Click | Right-click | Scroll |
|--------|-------|-------------|--------|
| Media | Play/pause | Stop | Previous/Next |
| Updates | Open updater | - | - |
| Pulseaudio | pwvucontrol | - | Volume |
| Network | nmtui | - | - |
| Swayidle | Change idle time | - | - |

## Wallpaper

Two wallpaper layers:
- **Backdrop** (swww) - blurred background visible when scrolling
- **Workspace** (swaybg) - main wallpaper behind windows

### Change Wallpaper

```bash
# Via keybinding
Mod+Ctrl+W

# Manual
pkill swaybg; swaybg -i /path/to/wallpaper.png -m fill &
```

Wallpaper files: `~/.config/niri-setup/wallpapers/`

## Logout Menu (wlogout)

| Option | Action |
|--------|--------|
| Shutdown | `systemctl poweroff` |
| Reboot | `systemctl reboot` |
| Logout | `niri msg action quit --skip-confirmation` |
| Suspend | `systemctl suspend` |
| Lock | swaylock |

## Troubleshooting

### Validate Config

```bash
niri validate
```

### Reload Config

```bash
niri msg action load-config-file
```

### RAPL Power Monitoring (btop)

If btop doesn't show power consumption:

```bash
sudo setcap cap_dac_read_search,cap_sys_rawio,cap_perfmon=ep $(which btop)
```

### X11 Apps Not Working

Ensure xwayland-satellite is in spawn-at-startup.

### Grey Lock Screen on Idle

If swaylock shows a grey screen when triggered by swayidle (but works with Mod+L), remove `niri msg action do-screen-transition` from `swaylock.sh`. The screen transition command conflicts with swaylock's session lock acquisition when triggered via swayidle.

## Resources

- [Niri GitHub](https://github.com/YaLTeR/niri)
- [acaibowlz/niri-setup](https://github.com/acaibowlz/niri-setup)
- [Official Documentation](https://yalter.github.io/niri/)
- [ArchWiki](https://wiki.archlinux.org/title/Niri)
