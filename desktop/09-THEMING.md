# 09 - Theming

Colors, wallpapers, and visual customization.

## Color System

ML4W uses pywal for dynamic color generation.

### Pywal Colors

**Generated file:** `~/.config/hypr/colors.conf`

Colors are extracted from the current wallpaper and applied to:
- Hyprland borders and decorations
- Waybar
- Rofi
- SwayNC
- hyprlock

### Color Variables

```bash
$background = rgba(...)
$foreground = rgba(...)
$color0 through $color15  # Terminal colors
$primary
$secondary
```

### Regenerate Colors

```bash
# From current wallpaper
wal -i ~/.current_wallpaper

# Apply to configs
~/.config/hypr/scripts/wallpaper-restore.sh
```

## Wallpapers

### waypaper

GUI wallpaper selector.

```bash
waypaper

# Or keybinding
# Super + Ctrl + W
```

### Random Wallpaper

```bash
waypaper --random

# Or keybinding
# Super + Shift + W
```

### Wallpaper Location

Default folder:

```bash
cat ~/.config/ml4w/settings/wallpaper-folder.sh
# Usually ~/Pictures/wallpapers or ~/wallpaper
```

### hyprpaper

Backend for displaying wallpapers.

**Config:** `~/.config/hypr/hyprpaper.conf`

```bash
preload = /path/to/wallpaper.jpg
wallpaper = eDP-1,/path/to/wallpaper.jpg
```

### Restore Wallpaper

```bash
~/.config/hypr/scripts/wallpaper-restore.sh
```

## GTK Theme

### Settings

```bash
~/.config/hypr/scripts/gtk.sh
```

### Configuration Tools

```bash
# GTK settings
nwg-look

# Or
lxappearance
```

### Theme Files

```
~/.config/gtk-3.0/settings.ini
~/.config/gtk-4.0/settings.ini
```

## Qt Theme

### Environment Variable

In `~/.config/hypr/conf/custom.conf`:

```bash
env = QT_QPA_PLATFORMTHEME,qt5ct
```

### Configuration

```bash
qt5ct
qt6ct
```

## Cursor Theme

### Configuration

**File:** `~/.config/hypr/conf/cursor.conf`

```bash
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Bibata-Modern-Classic
```

### Set Cursor

```bash
# Via hyprctl
hyprctl setcursor Bibata-Modern-Classic 24
```

## Icon Theme

Set via GTK settings:

```bash
# In ~/.config/gtk-3.0/settings.ini
gtk-icon-theme-name=Papirus-Dark
```

## Fonts

### System Font

```bash
# Check current
fc-match

# Set via GTK
# In settings.ini
gtk-font-name=Noto Sans 11
```

### Nerd Fonts

Required for icons in Waybar and terminals:

- JetBrainsMono Nerd Font
- Font Awesome

## Waybar Themes

### Theme Switcher

```bash
~/.config/waybar/themeswitcher.sh

# Or keybinding
# Super + Ctrl + T
```

### Theme Location

```
~/.config/waybar/themes/
```

## Animations

### Toggle Animations

```bash
~/.config/hypr/scripts/toggle-animations.sh

# Or keybinding
# Super + Shift + A
```

### Animation Presets

```
~/.config/hypr/conf/animations/
```

### Configuration

**File:** `~/.config/hypr/conf/animation.conf`

```bash
source = ~/.config/hypr/conf/animations/animation-moving.conf
```

## Decorations

### Window Decorations

**File:** `~/.config/hypr/conf/decoration.conf`

```bash
source = ~/.config/hypr/conf/decorations/decoration-rounding.conf
```

### Border Colors

From pywal in `colors.conf`:

```bash
general {
    col.active_border = $color11
    col.inactive_border = $color8
}
```

## Screen Shaders (hyprshade)

Visual effects/filters using hyprshade.

### Toggle Shader

```bash
~/.config/hypr/scripts/hyprshade.sh

# Or keybinding
# Super + Shift + H
```

### Shader Selector GUI

```bash
~/.config/hypr/scripts/hyprshade.sh rofi
```

### Available Shaders

```
~/.config/hypr/shaders/
├── blue-light-filter-25.glsl
├── blue-light-filter-50.glsl
├── blue-light-filter-75.glsl
└── invert-colors.glsl
```

### Automatic Scheduling (Sunset/Sunrise)

**Config:** `~/.config/hyprshade/config.toml`

```toml
[[shades]]
name = "blue-light-filter-50"
start_time = 16:30:00
end_time = 07:30:00

[[shades]]
name = "vibrance"
default = true
```

**Systemd timer:** Checks every 5 minutes and applies correct shader.

```bash
# Install systemd units
hyprshade install

# Enable timer
systemctl --user enable --now hyprshade.timer

# Check status
systemctl --user status hyprshade.timer

# Manual apply
hyprshade auto

# Check current shader
hyprshade current
```

**Timer config:** `~/.config/systemd/user/hyprshade.timer`

```ini
[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true
```

### Game Mode

Disables effects for gaming:

```bash
~/.config/hypr/scripts/gamemode.sh

# Or keybinding
# Super + Alt + G
```

## ML4W Settings App

GUI for many theme settings:

```bash
ml4w-hyprland-settings
```

Configures:
- Blur
- Animations
- Decorations
- Waybar options
- And more

## Quick Reference

```bash
# Wallpaper
waypaper                              # GUI selector
waypaper --random                     # Random
~/.config/hypr/scripts/wallpaper-restore.sh  # Restore

# Colors
wal -i /path/to/image                 # Generate colors

# Themes
~/.config/waybar/themeswitcher.sh     # Waybar theme

# GTK
nwg-look                              # GTK settings

# Animations
~/.config/hypr/scripts/toggle-animations.sh

# Settings app
ml4w-hyprland-settings
```

## Related

- [05-WAYBAR](./05-WAYBAR.md) - Bar theming
- [06-LAUNCHERS](./06-LAUNCHERS.md) - Rofi theming
- [08-LOCKSCREEN](./08-LOCKSCREEN.md) - Lock screen theming
