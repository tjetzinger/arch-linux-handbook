# 11 - Customization

Adding custom configurations to Hyprland/ML4W.

## ML4W Migration Guide

### Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| 2.9.9.5 | 2026-01 | swww replaces hyprpaper, Hyprland 0.53.x windowrule syntax, transparent Global Theme |
| 2.9.9.4 | 2025-12 | Previous stable |

### Migration Process

1. **Backup** - Use Dotfiles Installer's built-in backup (Settings → Backup)
2. **Update** - Run Dotfiles Installer and select Update
3. **Verify** - Check customizations are intact (see checklist below)
4. **Restore** - Restore any overwritten files from backup

### Backup Location

```
~/.var/app/com.ml4w.dotfilesinstaller/data/backup/com.ml4w.dotfiles.stable/<timestamp>/
```

### What Gets Backed Up

- `~/.config/hypr/`
- `~/.config/waybar/`
- `~/.config/ml4w/`
- Other desktop config directories

## Dotfiles

All custom configuration files are available in the [dotfiles](../dotfiles/) directory for easy deployment.

```bash
# Quick deploy (see dotfiles/README.md for full instructions)
cp -r ../dotfiles/hypr/conf/* ~/.config/hypr/conf/
cp ../dotfiles/hypr/hypridle-custom.conf ~/.config/hypr/
cp ../dotfiles/waybar/modules-custom.json ~/.config/waybar/
```

## Golden Rule

**Never edit ML4W default files directly.** Use the designated custom files instead.

## Migration-Safe File Structure

Keep customizations in separate files that ML4W won't overwrite during updates:

```
~/.config/hypr/
├── hypridle-custom.conf         # Custom idle config (SAFE)
├── monitors.conf                # hyprdynamicmonitors output (SAFE)
├── conf/
│   ├── custom.conf              # Main custom file (SAFE)
│   ├── ttkeyboard.conf          # Custom keyboard/input (SAFE)
│   ├── autostart-custom.conf    # Custom autostart (SAFE)
│   ├── windowrules/
│   │   ├── default.conf         # ML4W default (OVERWRITTEN)
│   │   └── custom.conf          # Custom rules (SAFE)
│   ├── keybindings/
│   │   ├── default.conf         # ML4W default (OVERWRITTEN)
│   │   └── custom.conf          # Custom bindings (SAFE)
│   ├── autostart.conf           # ML4W default (OVERWRITTEN)
│   ├── keybinding.conf          # ML4W default (OVERWRITTEN)
│   └── windowrule.conf          # ML4W default (OVERWRITTEN)
├── hypridle.conf                # ML4W default (OVERWRITTEN - hardlinked)
└── hyprlock.conf                # ML4W default (OVERWRITTEN - hardlinked)

~/.config/waybar/
├── modules-custom.json          # Custom module overrides (SAFE)
├── modules.json                 # ML4W default (OVERWRITTEN - hardlinked)
└── themes/
    ├── ml4w-minimal/            # ML4W theme (OVERWRITTEN - hardlinked)
    │   ├── config
    │   └── style.css
    └── custom-minimal/          # Custom theme copy (SAFE)
        ├── config
        └── style.css
```

### Files ML4W May Overwrite
- `autostart.conf`
- `keybinding.conf`
- `windowrule.conf`
- `keybindings/default.conf`
- `windowrules/default.conf`
- `hypridle.conf` (hardlinked to ML4W dotfiles)
- `hyprlock.conf` (hardlinked to ML4W dotfiles)
- Most files in `decorations/`, `layouts/`, `animations/`
- `~/.config/waybar/modules.json` (hardlinked)
- `~/.config/waybar/themes/ml4w-*` (hardlinked)

### Files ML4W Won't Touch
- `custom.conf`
- `hypridle-custom.conf`
- `monitors.conf`
- Any file you create (e.g., `ttkeyboard.conf`, `autostart-custom.conf`)
- `keybindings/custom.conf`
- `windowrules/custom.conf`
- `~/.config/waybar/modules-custom.json`
- `~/.config/waybar/themes/custom-*`
- `~/.local/bin/*` (custom scripts)

## Post-Migration Restoration Checklist

After an ML4W update, verify these customizations are intact:

### ✅ Migration-Safe (no action needed)

These files are yours and won't be touched by ML4W:

| File | Purpose |
|------|---------|
| `~/.config/hypr/hypridle-custom.conf` | Custom idle timeouts (no auto-lock, no suspend) |
| `~/.config/hypr/conf/autostart-custom.conf` | Starts hypridle with custom config |
| `~/.local/bin/hypridle-toggle` | Waybar toggle using custom config |
| `~/.local/bin/restart-hypridle` | Manual restart with custom config |
| `~/.config/waybar/modules-custom.json` | Waybar module overrides |

### ⚠️ May Need Restoration

**1. Waybar theme include order**

File: `~/.config/waybar/themes/ml4w-minimal/config`

Verify `modules-custom.json` is **first** in include array (first takes precedence):

```json
"include": [
    "~/.config/waybar/modules-custom.json",
    "~/.config/ml4w/settings/waybar-quicklinks.json",
    "~/.config/waybar/modules.json"
]
```

**2. Default hypridle autostart**

File: `~/.config/hypr/conf/autostart.conf`

Verify the default hypridle line is commented out (your `autostart-custom.conf` handles it):

```bash
# exec-once = hypridle
```

### Quick Verification Commands

```bash
# Check hypridle is using custom config
ps aux | grep hypridle
# Should show: hypridle -c /home/tt/.config/hypr/hypridle-custom.conf

# Check waybar include order
head -15 ~/.config/waybar/themes/ml4w-minimal/config

# Check autostart
grep hypridle ~/.config/hypr/conf/autostart.conf
```

### Hypridle Custom Configs

Two configs for different idle behaviors:

| Config | Lock Screen | Screen Off | Suspend |
|--------|-------------|------------|---------|
| `hypridle-custom.conf` | 10min | 11min | No |
| `hypridle-inhibit.conf` | No | 11min | No |

**`~/.config/hypr/hypridle-custom.conf`** - Normal mode (with lock):

```bash
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 480                                # 8min dim
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

listener {
    timeout = 600                                # 10min lock
    on-timeout = loginctl lock-session
}

listener {
    timeout = 660                                # 11min screen off
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on && brightnessctl -r
}
```

**`~/.config/hypr/hypridle-inhibit.conf`** - Inhibit mode (no lock):

```bash
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 480                                # 8min dim
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

# No lock screen when inhibitor is active

listener {
    timeout = 660                                # 11min screen off
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on && brightnessctl -r
}
```

### Hypridle Toggle Script

**`~/.local/bin/hypridle-toggle`** - Switches between normal and inhibit configs:

```bash
#!/bin/bash
# Switches between full config (with lock) and inhibit config (no lock)
SERVICE="hypridle"
FULL_CONFIG="$HOME/.config/hypr/hypridle-custom.conf"
INHIBIT_CONFIG="$HOME/.config/hypr/hypridle-inhibit.conf"
STATE_FILE="$HOME/.cache/hypridle-inhibit-state"

is_inhibited() { [[ -f "$STATE_FILE" ]]; }

print_status() {
    if is_inhibited; then
        echo '{"text": "INHIBITED", "class": "notactive", "tooltip": "Lock disabled\nScreen off: 11min\nLeft: Enable lock\nRight: Lock now"}'
    else
        echo '{"text": "NORMAL", "class": "active", "tooltip": "Lock enabled\nLock: 10min, Screen off: 11min\nLeft: Disable lock\nRight: Lock now"}'
    fi
}

restart_hypridle() {
    killall "$SERVICE" 2>/dev/null; sleep 0.2
    "$SERVICE" -c "$1" &
}

case "$1" in
    status) sleep 0.2; print_status ;;
    toggle)
        if is_inhibited; then
            rm -f "$STATE_FILE"
            restart_hypridle "$FULL_CONFIG"
        else
            touch "$STATE_FILE"
            restart_hypridle "$INHIBIT_CONFIG"
        fi
        sleep 0.3; print_status ;;
    *) echo "Usage: $0 {status|toggle}"; exit 1 ;;
esac
```

| Toggle State | Config Used | Behavior |
|--------------|-------------|----------|
| NORMAL (off) | hypridle-custom.conf | 8min dim → 10min lock → 11min screen off |
| INHIBITED (on) | hypridle-inhibit.conf | 8min dim → 11min screen off (no lock) |

**`~/.local/bin/restart-hypridle`** - Manual restart:

```bash
#!/usr/bin/env bash
killall hypridle
sleep 1
hypridle -c ~/.config/hypr/hypridle-custom.conf &
notify-send "hypridle restarted (custom config)"
```

### Waybar Module Override

**`~/.config/waybar/modules-custom.json`** should include:

```json
{
    "custom/hypridle": {
        "format": "",
        "return-type": "json",
        "escape": true,
        "exec-on-event": true,
        "interval": 60,
        "exec": "~/.local/bin/hypridle-toggle status",
        "on-click": "~/.local/bin/hypridle-toggle toggle",
        "on-click-right": "hyprlock"
    }
}
```

**Important:** The `"format": ""` field contains a Font Awesome lock icon (U+F023 ) that appears invisible in most editors. This icon MUST be preserved - an empty string will make the module invisible in waybar.

To copy the icon from the original config:
```bash
python3 -c "
import json, re
with open('$HOME/.config/waybar/modules.json') as f:
    match = re.search(r'\"custom/hypridle\"[^}]*\"format\": \"([^\"]+)\"', f.read())
    if match: print(f'Icon: {repr(match.group(1))}')
"
# Output: Icon: '\uf023'
```

## custom.conf

The main file for your customizations.

**File:** `~/.config/hypr/conf/custom.conf`

### What Goes Here

- Environment variables
- Device-specific settings
- Plugin configuration
- Additional keybindings
- Custom window rules
- Sourcing additional configs

### Example Content

```bash
# Environment variables
env = SDL_VIDEODRIVER,wayland
env = QT_QPA_PLATFORMTHEME,qt5ct

# Device-specific: Mouse scroll inversion
device {
    name = m585/m590-mouse
    natural_scroll = true
}

# Plugin configuration
plugin {
    split-monitor-workspaces {
        count = 3
        keep_focused = 0
        enable_notifications = 0
    }
}

# Additional keybindings
bind = $mainMod, H, exec, warp-terminal -e htop

# Custom window rules
windowrule = float,class:(calculator)
windowrule = size 400 600,class:(calculator)

# Source additional custom files
source = ~/.config/hypr/conf/ttkeyboard.conf
source = ~/.config/hypr/conf/windowrules/custom.conf
source = ~/.config/hypr/conf/autostart-custom.conf
```

## Keyboard & Input Settings

Create `~/.config/hypr/conf/ttkeyboard.conf` for keyboard layout and touchpad settings:

```bash
# -----------------------------------------------------
# Keyboard Layout
# https://wiki.hyprland.org/Configuring/Variables/#input
# -----------------------------------------------------
input {
    kb_layout = de
    kb_variant = nodeadkeys
    kb_model = thinkpad
    kb_options =
    numlock_by_default = true
    mouse_refocus = false

    # For United States layout (alternative)
    # kb_layout = us
    # kb_variant = intl
    # kb_model = pc105

    follow_mouse = 1
    touchpad {
        natural_scroll = true
        middle_button_emulation = true
        clickfinger_behavior = true
        tap-to-click = true
        drag_lock = true
        scroll_factor = 1.0
    }
    sensitivity = 0  # -1.0 to 1.0, 0 = no modification
}
```

### Keyboard Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `kb_layout` | `de` | German layout |
| `kb_variant` | `nodeadkeys` | No dead keys (direct character input) |
| `kb_model` | `thinkpad` | ThinkPad keyboard model |
| `numlock_by_default` | `true` | Numlock on at startup |

### Touchpad Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `natural_scroll` | `true` | Inverted scroll (like macOS/mobile) |
| `middle_button_emulation` | `true` | Three-finger tap = middle click |
| `clickfinger_behavior` | `true` | Click position determines button |
| `tap-to-click` | `true` | Tap to click enabled |
| `drag_lock` | `true` | Lift finger during drag without dropping |

### Per-Device Overrides

For device-specific settings (in `custom.conf`):

```bash
# External mouse - invert scroll
device {
    name = m585/m590-mouse
    natural_scroll = true
}

# External keyboard - different layout
device {
    name = mx-keys-mini-keyboard
    kb_layout = de
    kb_variant = nodeadkeys
}
```

Find device names with:
```bash
hyprctl devices
```

## Custom Window Rules

Create `~/.config/hypr/conf/windowrules/custom.conf`:

```bash
# -----------------------------------------------------
# Custom Window Rules (persists across ML4W updates)
# -----------------------------------------------------

# System utilities - float
windowrulev2 = float, title:(pavucontrol)
windowrulev2 = float, title:(blueman-manager)
windowrulev2 = float, title:(nm-connection-editor)
windowrulev2 = float, title:(qalculate-gtk)

# Browser Picture in Picture
windowrulev2 = float, title:(Picture-in-Picture)
windowrulev2 = pin, title:(Picture-in-Picture)
windowrulev2 = move 69.5% 4%, title:(Picture-in-Picture)

# Idle inhibit for fullscreen apps
windowrulev2 = idleinhibit fullscreen, class:(.*)

# XWayland fixes (DaVinci Resolve)
windowrulev2 = noblur, class:(resolve), xwayland:1

# Waydroid (Android apps)
windowrulev2 = float, class:(Waydroid)
windowrulev2 = size 480 800, class:(Waydroid)
windowrulev2 = center, class:(Waydroid)
windowrulev2 = idleinhibit focus, class:(Waydroid)
```

Then source it from `custom.conf`:
```bash
source = ~/.config/hypr/conf/windowrules/custom.conf
```

## Custom Autostart

Create `~/.config/hypr/conf/autostart-custom.conf`:

```bash
# -----------------------------------------------------
# Custom Autostart (persists across ML4W updates)
# -----------------------------------------------------

# XDG portal for screen sharing
exec-once = ~/.config/hypr/scripts/xdg.sh

# Dock
exec-once = ~/.config/nwg-dock-hyprland/launch.sh

# Load hyprpm plugins
exec-once = hyprpm reload -n
```

Then source it from `custom.conf`:
```bash
source = ~/.config/hypr/conf/autostart-custom.conf
```

## Adding Keybindings

### In custom.conf

```bash
# Variables (already defined in keybindings)
$mainMod = SUPER
$HYPRSCRIPTS = ~/.config/hypr/scripts
$SCRIPTS = ~/.config/ml4w/scripts

# New keybinding
bind = $mainMod, H, exec, warp-terminal -e htop
bind = $mainMod ALT, F, exec, firefox --private-window
bind = $mainMod, N, exec, nautilus
```

### Keybinding Syntax

```bash
bind = MODIFIERS, key, dispatcher, params

# Examples
bind = $mainMod, Q, killactive
bind = $mainMod, F, fullscreen, 0
bind = $mainMod, T, exec, warp-terminal
bind = $mainMod SHIFT, S, exec, ~/.config/hypr/scripts/screenshot.sh
```

### Modifiers

| Modifier | Key |
|----------|-----|
| SUPER | Super/Windows key |
| SHIFT | Shift |
| CTRL | Control |
| ALT | Alt |

### Bind Types

| Type | Description |
|------|-------------|
| bind | Standard binding |
| binde | Repeats while held |
| bindm | Mouse binding |
| bindl | Works when locked |
| bindr | On key release |

## Window Rules

### Syntax

```bash
windowrule = RULE, MATCH
windowrulev2 = RULE, MATCH1, MATCH2, ...
```

### Common Rules

```bash
# Float a window
windowrule = float,class:(pavucontrol)

# Set size
windowrule = size 800 600,class:(pavucontrol)

# Set position
windowrule = move 100 100,class:(myapp)

# Center window
windowrule = center,class:(myapp)

# Pin (always on top)
windowrule = pin,class:(myapp)

# Opacity
windowrule = opacity 0.9,class:(myapp)

# Workspace assignment
windowrule = workspace 2,class:(firefox)
```

### Match Criteria

```bash
class:(regex)      # Window class
title:(regex)      # Window title
initialClass:(regex)
initialTitle:(regex)
```

### Find Window Class

```bash
# List all windows with class
hyprctl clients | grep class

# Or use hyprprop (click on window)
# Might need to install hyprland-contrib
```

## Environment Variables

### In custom.conf

```bash
env = VARIABLE,value
```

### Common Variables

```bash
# Wayland
env = SDL_VIDEODRIVER,wayland
env = GDK_BACKEND,wayland
env = QT_QPA_PLATFORM,wayland

# Qt theming
env = QT_QPA_PLATFORMTHEME,qt5ct

# Cursor
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Bibata-Modern-Classic

# XDG
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
```

## Custom Keybindings

For extensive keybinding changes, create `~/.config/hypr/conf/keybindings/custom.conf`:

```bash
# Volume - 1% increments (default is 5%)
bind = , XF86AudioRaiseVolume, exec, pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ +1%
bind = , XF86AudioLowerVolume, exec, pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ -1%

# split-monitor-workspaces plugin bindings
bind = $mainMod, 1, split-workspace, 1
bind = $mainMod, 2, split-workspace, 2
# ... etc
```

Then update `keybinding.conf` to source your custom file:
```bash
source = ~/.config/hypr/conf/keybindings/custom.conf
```

**Note:** If `keybinding.conf` gets reset by ML4W, you'll need to change it back.

## Waybar Customization

### Migration-Safe Module Overrides

Waybar modules are defined in `~/.config/waybar/modules.json` (hardlinked to ML4W). To override settings migration-safely:

1. Create `~/.config/waybar/modules-custom.json` with your overrides
2. Add it FIRST in the theme config's include array

**File:** `~/.config/waybar/modules-custom.json`

```json
{
    "hyprland/workspaces": {
        "all-outputs": false,
        "persistent-workspaces": {
            "*": 3
        }
    }
}
```

**Theme config:** `~/.config/waybar/themes/<theme>/config`

```json
"include": [
    "~/.config/waybar/modules-custom.json",
    "~/.config/ml4w/settings/waybar-quicklinks.json",
    "~/.config/waybar/modules.json"
],
```

**Caveat:** Theme configs are hardlinked to ML4W. After updates, re-add the custom include.

### Fully Migration-Safe: Custom Theme

For a fully migration-safe setup, create a copy of your preferred theme:

```bash
# Copy theme
cp -r ~/.config/waybar/themes/ml4w-minimal ~/.config/waybar/themes/custom-minimal

# Edit the custom theme's config
$EDITOR ~/.config/waybar/themes/custom-minimal/config

# Switch to custom theme
~/.config/waybar/themeswitcher.sh
```

Custom themes in `~/.config/waybar/themes/` are not overwritten by ML4W updates.

### Per-Monitor Workspaces

See [05-WAYBAR.md](./05-WAYBAR.md#per-monitor-workspaces-split-monitor-workspaces) for configuring waybar to show only each monitor's workspaces when using split-monitor-workspaces plugin.

## Wallpaper Engine

ML4W 2.9.9.5+ uses **swww** by default (hyprpaper 0.8.0 broke waypaper compatibility).

### Check Current Engine
```bash
cat ~/.config/ml4w/settings/wallpaper-engine.sh
```

### Switch to swww
```bash
echo "swww" > ~/.config/ml4w/settings/wallpaper-engine.sh
pkill hyprpaper
swww-daemon &
```

### Update waypaper Backend
Edit `~/.config/waypaper/config.ini`:
```ini
backend = swww
```

## Autostart

### Adding Autostart Apps

**Recommended:** Use `autostart-custom.conf` (see above) instead of editing `autostart.conf`.

```bash
# Run once at startup
exec-once = /path/to/app

# Run every config reload
exec = /path/to/script
```

### Examples

```bash
exec-once = nm-applet
exec-once = blueman-applet
exec-once = /usr/lib/kdeconnectd
```

## Custom Scripts

### Location

```bash
~/.config/hypr/scripts/
~/.config/ml4w/scripts/
```

### Create Script

```bash
#!/bin/bash
# ~/.config/hypr/scripts/my-script.sh

# Your commands here
notify-send "Hello" "Script executed"
```

```bash
chmod +x ~/.config/hypr/scripts/my-script.sh
```

### Use in Keybinding

```bash
bind = $mainMod, X, exec, ~/.config/hypr/scripts/my-script.sh
```

## Plugins

### Installing Plugins

```bash
# Add plugin repository
hyprpm add https://github.com/username/plugin

# Enable plugin
hyprpm enable plugin-name

# Update plugins
hyprpm update
```

### Plugin Config

In custom.conf:

```bash
plugin {
    plugin-name {
        setting1 = value
        setting2 = value
    }
}
```

### Current Plugin

**split-monitor-workspaces** - Per-monitor workspaces

```bash
plugin {
    split-monitor-workspaces {
        count = 3
        keep_focused = 0
        enable_notifications = 0
    }
}
```

## ML4W Settings App

GUI for many settings:

```bash
ml4w-hyprland-settings
```

Generates config at:
```
~/.config/com.ml4w.hyprlandsettings/
```

## Testing Changes

### Reload Config

```bash
hyprctl reload

# Or keybinding
# Super + Ctrl + R
```

### Check for Errors

```bash
# Watch logs while reloading
journalctl --user -f | grep -i hypr
```

### Validate Window Rules

```bash
# List active rules
hyprctl getoption windowrule
```

## Backup Custom Config

```bash
# Before major changes
cp ~/.config/hypr/conf/custom.conf ~/.config/hypr/conf/custom.conf.bak
```

## Quick Reference

```bash
# Edit custom config
$EDITOR ~/.config/hypr/conf/custom.conf

# Reload config
hyprctl reload

# List windows (for rules)
hyprctl clients

# List monitors
hyprctl monitors

# Check devices (for device config)
hyprctl devices

# Plugin management
hyprpm list
hyprpm add <repo>
hyprpm enable <plugin>
```

## Related

- [02-CONFIGURATION](./02-CONFIGURATION.md) - Config structure
- [03-KEYBINDINGS](./03-KEYBINDINGS.md) - Keybinding reference
- [01-OVERVIEW](./01-OVERVIEW.md) - Plugin information
