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
    mouse {
        scroll-factor 0.93
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
| Volume Up/Down | Adjust volume ±1% |
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
| `Mod+Arrow` | Focus column/window |
| `Mod+Alt+Left/Right` | Focus monitor |
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

## Alacritty

Config: `~/.config/niri-setup/alacritty/alacritty.toml`

| Keybinding | Action |
|-----------|--------|
| `Shift+Return` | Send `Esc + Return` (useful for niri's consume-or-expel in terminal) |

## Monitor Configuration (outputs.kdl)

Niri matches monitors by output name. Use the full EDID description string (from `niri msg outputs`) instead of connector names (`DP-1`, `DP-2`) — connector names change on every dock disconnect/reconnect.

```bash
# Find stable monitor identifiers
niri msg outputs | grep "^Output"
# Output "PNP(BNQ) BenQ BL2581T ET1CL03348SL0" (DP-8)
# Output "PNP(BNQ) BenQ BL2581T ET1CL03342SL0" (DP-9)
# Output "AU Optronics 0xD291 Unknown" (eDP-1)
```

### Dock Setup (2x BenQ BL2581T + Laptop)

```kdl
// Left: BenQ BL2581T (serial ..48SL0)
output "PNP(BNQ) BenQ BL2581T ET1CL03348SL0" {
    mode "1920x1200@59.950"
    scale 1.0
    transform "normal"
    position x=0 y=0
}

// Center: BenQ BL2581T (serial ..42SL0)
output "PNP(BNQ) BenQ BL2581T ET1CL03342SL0" {
    mode "1920x1200@59.950"
    scale 1.0
    transform "normal"
    position x=1920 y=0
}

// Right: Laptop display
output "eDP-1" {
    mode "1920x1200@60.026"
    scale 1.25
    transform "normal"
    position x=3840 y=0
}
```

| Identifier type | Example | Stable across hotplug? |
|----------------|---------|----------------------|
| Connector name | `DP-8` | No — changes every reconnect |
| EDID description | `PNP(BNQ) BenQ BL2581T ET1CL03348SL0` | Yes — tied to physical monitor |
| `eDP-1` | Laptop panel | Yes — always the same |

### Reload After Changes

```bash
niri msg action load-config-file
niri msg outputs | grep -E "^Output|Logical position"
```

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

If swaylock shows a grey screen when triggered by swayidle (but Mod+L works fine):

**Cause 1: Conflicting swayidle config file**

swayidle reads both command line arguments AND `~/.config/swayidle/config`. If both exist, the config file's `swaylock -f` (bare swaylock = grey) runs first.

```bash
# Check for conflicting config
cat ~/.config/swayidle/config

# If it contains "swaylock -f", remove or backup:
mv ~/.config/swayidle/config ~/.config/swayidle/config.bak
```

**Cause 2: `--daemonize` flag in swaylock.sh**

The `--daemonize` flag causes swaylock to fork into the background immediately. swayidle then thinks the lock command finished and may proceed to the next timeout (power off monitors / suspend) before the lock is fully rendered, resulting in a grey screen.

**Fix:** Remove `--daemonize` from `scripts/swaylock.sh`.

**Cause 3: `niri msg action do-screen-transition`**

The screen transition effect before swaylock can race with the lock surface, causing a grey flash.

**Fix:** Remove the `do-screen-transition` line from `scripts/swaylock.sh`.

**swaylock.sh fixes applied:**

```bash
#!/bin/bash

# Prevent duplicate locks (ext-session-lock-v1 only allows one client)
pgrep -x swaylock && exit 0

swaylock \
  --clock \
  --screenshots \
  --ignore-empty-password \
  ...
```

The duplicate-lock guard prevents a second swaylock instance from racing with an existing one. The `ext-session-lock-v1` Wayland protocol only allows one client to hold the session lock.

**Restart swayidle after changes:**

```bash
pkill swayidle
~/.config/niri-setup/scripts/swayidle.sh &
```

## Blue Light Filter (wlsunset)

Install and configure wlsunset as a systemd user service:

```bash
yay -S wlsunset
```

Create `~/.config/systemd/user/wlsunset.service`:

```ini
[Unit]
Description=Day/night gamma adjustments
Documentation=man:wlsunset(1)
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/wlsunset -l 48.1 -L 11.6 -t 4000 -T 6500
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

Enable and start:

```bash
systemctl --user enable --now wlsunset.service
```

Toggle modes (day/night/auto): `pkill -USR1 wlsunset`

## Logitech MX Master 3S (logiops)

Configure gesture button and thumbwheel via logiops.

```bash
yay -S logiops
sudo systemctl enable --now logid
```

Config: `/etc/logid.cfg`

### Gesture Button

| Gesture | Action |
|---------|--------|
| Tap | Overview |
| Swipe Left | Focus column right |
| Swipe Right | Focus column left |
| Swipe Up | Workspace down |
| Swipe Down | Workspace up |

Gestures use natural direction (content moves with swipe).

### Thumbwheel

Volume control at 1% step per scroll tick.

See [hardware/08-PERIPHERALS](../hardware/08-PERIPHERALS.md) for full configuration.

## Resources

- [Niri GitHub](https://github.com/YaLTeR/niri)
- [acaibowlz/niri-setup](https://github.com/acaibowlz/niri-setup)
- [Official Documentation](https://yalter.github.io/niri/)
- [ArchWiki](https://wiki.archlinux.org/title/Niri)
