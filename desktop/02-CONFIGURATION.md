# 02 - Configuration

Hyprland configuration file structure and organization.

## Main Config File

**File:** `~/.config/hypr/hyprland.conf`

This file sources all other configuration files:

```bash
source = ~/.config/hypr/conf/monitor.conf
source = ~/.config/hypr/conf/cursor.conf
source = ~/.config/hypr/conf/environment.conf
source = ~/.config/hypr/conf/keyboard.conf
source = ~/.config/hypr/colors.conf
source = ~/.config/hypr/conf/autostart.conf
source = ~/.config/hypr/conf/window.conf
source = ~/.config/hypr/conf/decoration.conf
source = ~/.config/hypr/conf/layout.conf
source = ~/.config/hypr/conf/workspace.conf
source = ~/.config/hypr/conf/misc.conf
source = ~/.config/hypr/conf/keybinding.conf
source = ~/.config/hypr/conf/windowrule.conf
source = ~/.config/hypr/conf/animation.conf
source = ~/.config/hypr/conf/ml4w.conf
source = ~/.config/hypr/conf/custom.conf
```

**Important:** Don't edit `hyprland.conf` directly. Use `custom.conf` for your changes.

## Directory Structure

```
~/.config/hypr/
├── hyprland.conf           # Main config (don't edit)
├── hypridle.conf           # Idle daemon config
├── hyprlock.conf           # Lock screen config
├── hyprpaper.conf          # Wallpaper daemon
├── colors.conf             # Pywal-generated colors
├── monitors.conf           # Symlink to active monitor config
│
├── conf/                   # Modular configuration
│   ├── animation.conf      # → animations/
│   ├── animations/         # Animation presets
│   ├── autostart.conf      # Startup applications
│   ├── cursor.conf         # Cursor settings
│   ├── custom.conf         # YOUR CUSTOMIZATIONS
│   ├── decoration.conf     # → decorations/
│   ├── decorations/        # Decoration presets
│   ├── environment.conf    # → environments/
│   ├── environments/       # Environment variables
│   ├── keybinding.conf     # → keybindings/
│   ├── keybindings/        # Keybinding presets
│   ├── keyboard.conf       # Keyboard layout
│   ├── layout.conf         # → layouts/
│   ├── layouts/            # Tiling layouts
│   ├── misc.conf           # Miscellaneous settings
│   ├── ml4w.conf           # ML4W-specific rules
│   ├── monitor.conf        # → monitors/
│   ├── monitors/           # Monitor presets
│   ├── ttkeyboard.conf     # Custom keyboard config
│   ├── window.conf         # → windows/
│   ├── windows/            # Window settings
│   ├── windowrule.conf     # → windowrules/
│   ├── windowrules/        # Window rules
│   ├── workspace.conf      # → workspaces/
│   └── workspaces/         # Workspace settings
│
├── scripts/                # Helper scripts
│   ├── screenshot.sh
│   ├── toggle-animations.sh
│   ├── wallpaper-restore.sh
│   └── ...
│
├── shaders/                # Visual effect shaders
└── effects/                # Effect configurations
```

## Configuration Files

### custom.conf (Your Customizations)

**File:** `~/.config/hypr/conf/custom.conf`

This is where you add your personal settings:

```bash
# Environment variables
env = SDL_VIDEODRIVER,wayland

# Device-specific settings (scroll direction, etc.)
device {
    name = m585/m590-mouse
    natural_scroll = true
}

device {
    name = tpps/2-elan-trackpoint
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
# bind = $mainMod CTRL, up, workspace, empty

# Include other custom files
source = ~/.config/hypr/conf/ttkeyboard.conf
```

### autostart.conf

**File:** `~/.config/hypr/conf/autostart.conf`

Applications started on login:

```bash
exec-once = ~/.config/hypr/scripts/xdg.sh
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = ~/.config/hypr/scripts/wallpaper-restore.sh
exec-once = swaync
exec-once = ~/.config/hypr/scripts/gtk.sh
exec-once = hypridle
exec-once = wl-paste --watch cliphist store
exec-once = ~/.config/ml4w/scripts/ml4w-autostart.sh
exec-once = ~/.config/hypr/scripts/cleanup.sh
exec = ~/.config/com.ml4w.hyprlandsettings/hyprctl.sh
exec-once = ~/.config/nwg-dock-hyprland/launch.sh
exec-once = hyprdynamicmonitors run --enable-lid-events
exec-once = hyprpm reload -n
```

### keyboard.conf

**File:** `~/.config/hypr/conf/keyboard.conf`

```bash
input {
    kb_layout = de
    kb_variant = nodeadkeys
    kb_model = thinkpad
    kb_options =
    kb_rules =
    numlock_by_default = true

    follow_mouse = 1

    touchpad {
        natural_scroll = true
        disable_while_typing = true
    }

    sensitivity = 0
}
```

### ml4w.conf

**File:** `~/.config/hypr/conf/ml4w.conf`

ML4W-specific window rules:

```bash
# Pavucontrol floating
windowrule = float,class:(.*org.pulseaudio.pavucontrol.*)
windowrule = size 700 600,class:(.*org.pulseaudio.pavucontrol.*)
windowrule = center,class:(.*org.pulseaudio.pavucontrol.*)

# Waypaper
windowrule = float,class:(.*waypaper.*)
windowrule = size 900 700,class:(.*waypaper.*)

# SwayNC blur
layerrule = blur, swaync-control-center
layerrule = blur, swaync-notification-window
```

## Sourcing Pattern

ML4W uses a pattern where config files source from subdirectories:

```bash
# In conf/animation.conf
source = ~/.config/hypr/conf/animations/animation-moving.conf
```

This allows switching presets by changing a single line.

## Reloading Configuration

```bash
# Reload Hyprland config
hyprctl reload

# Or use keybinding
# Super + Ctrl + R
```

## Checking Configuration

```bash
# Validate config
hyprctl monitors    # Check monitor config
hyprctl devices     # Check input devices
hyprctl clients     # List windows

# Check for errors
journalctl --user -u hyprland
```

## Input Devices

### Finding Device Names

```bash
# List all input devices
hyprctl devices
```

### Per-Device Configuration

Add to `~/.config/hypr/conf/custom.conf`:

```bash
# TrackPoint - invert scroll direction
device {
    name = tpps/2-elan-trackpoint
    natural_scroll = true
}

# External mouse
device {
    name = m585/m590-mouse
    natural_scroll = true
}

# External keyboard with different layout
device {
    name = mx-keys-mini-keyboard
    kb_layout = de
    kb_variant = nodeadkeys
}
```

### Available Device Options

| Option | Description |
|--------|-------------|
| `natural_scroll` | Invert scroll direction (true/false) |
| `sensitivity` | Pointer speed (-1.0 to 1.0) |
| `accel_profile` | `flat` or `adaptive` |
| `kb_layout` | Keyboard layout (e.g., `de`, `us`) |
| `kb_variant` | Layout variant (e.g., `nodeadkeys`) |

## Environment Variables

Set in `conf/environment.conf` or `conf/custom.conf`:

```bash
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = SDL_VIDEODRIVER,wayland
```

## Quick Reference

```bash
# Edit custom config
$EDITOR ~/.config/hypr/conf/custom.conf

# Reload config
hyprctl reload

# Check config syntax (no built-in validator)
# Watch for errors in:
journalctl --user -f

# List all config options
hyprctl getoption <option>
```

## Related

- [03-KEYBINDINGS](./03-KEYBINDINGS.md) - Keybinding configuration
- [04-MONITORS](./04-MONITORS.md) - Monitor setup
- [11-CUSTOMIZATION](./11-CUSTOMIZATION.md) - Custom modifications
