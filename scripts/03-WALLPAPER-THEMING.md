# 03 - Wallpaper & Theming Scripts

Wallpaper management, color generation, and visual effects.

## Main Wallpaper Script (wallpaper.sh)

**Location:** `~/.config/hypr/scripts/wallpaper.sh`

The central script for wallpaper management with color scheme generation.

### Usage

```bash
# Set specific wallpaper
~/.config/hypr/scripts/wallpaper.sh /path/to/image.jpg

# Restore last wallpaper (no argument)
~/.config/hypr/scripts/wallpaper.sh
```

### Features

1. **Wallpaper Application** - Sets wallpaper via waypaper
2. **Color Generation** - Runs matugen for system-wide theming
3. **Caching** - Caches processed wallpapers for performance
4. **Effects** - Applies configured visual effects
5. **Component Refresh** - Updates waybar, swaync, pywalfox

### Process Flow

```
1. Load wallpaper source image
2. Apply wallpaper effect (if configured)
3. Run matugen for color scheme
4. Refresh waybar (SIGUSR2)
5. Refresh nwg-dock
6. Update pywalfox (if installed)
7. Refresh swaync
8. Generate blurred version for rofi
9. Create square version
```

### Configuration Files

```
~/.config/ml4w/settings/blur.sh              # Blur amount (e.g., "50x30")
~/.config/ml4w/settings/wallpaper-effect.sh  # Active effect name
~/.config/ml4w/cache/current_wallpaper       # Path to current wallpaper
~/.config/ml4w/cache/wallpaper-generated/    # Cached processed versions
```

### Cache Behavior

If `~/.config/ml4w/settings/wallpaper_cache` exists:
- Uses cached processed wallpapers when available
- Significantly faster wallpaper switching
- Delete cache file to always regenerate

## Wallpaper Effects (wallpaper-effects.sh)

**Location:** `~/.config/hypr/scripts/wallpaper-effects.sh`

Select and apply visual effects to wallpapers.

### Usage

```bash
# Open rofi effect selector
~/.config/hypr/scripts/wallpaper-effects.sh

# Reload with current effect
~/.config/hypr/scripts/wallpaper-effects.sh reload
```

### Available Effects

Effects are stored in `~/.config/hypr/effects/wallpaper/`:

| Effect | Description |
|--------|-------------|
| `off` | No effect |
| `blackwhite` | Grayscale conversion |
| `blackwhite-blur` | Grayscale + blur |
| `blackwhite-brightness40` | Grayscale, 40% brightness |
| `blackwhite-brightness60` | Grayscale, 60% brightness |
| `blackwhite-brightness80` | Grayscale, 80% brightness |
| `blur1` | Light blur |
| `blur2` | Heavy blur |
| `blur1-brightness40` | Blur + 40% brightness |
| `negate` | Inverted colors |
| `negate-brightness40` | Inverted + 40% brightness |

### Creating Custom Effects

Effects are simple ImageMagick commands. Example:

```bash
# ~/.config/hypr/effects/wallpaper/sepia
magick $tmpwallpaper -sepia-tone 80% $used_wallpaper
```

## Wallpaper Automation (wallpaper-automation.sh)

**Location:** `~/.config/hypr/scripts/wallpaper-automation.sh`

Automatically rotate wallpapers at intervals.

### Usage

```bash
# Toggle automation on/off
~/.config/hypr/scripts/wallpaper-automation.sh
```

### Configuration

Interval set in `~/.config/ml4w/settings/wallpaper-automation.sh`:

```bash
# Set to number of seconds between changes
60    # Change every minute
300   # Change every 5 minutes
3600  # Change every hour
```

### Behavior

- When started: Sets random wallpapers at configured interval
- When running: Kills the automation process
- Flag file: `~/.config/ml4w/cache/wallpaper-automation`

## Hyprshade (hyprshade.sh)

**Location:** `~/.config/hypr/scripts/hyprshade.sh`

Toggle screen shaders/filters for eye comfort or effects.

### Usage

```bash
# Toggle current shader on/off
~/.config/hypr/scripts/hyprshade.sh

# Open rofi shader selector
~/.config/hypr/scripts/hyprshade.sh rofi
```

### Available Shaders

View with `hyprshade ls`:
- `blue-light-filter-50` - Reduce blue light (default)
- Custom shaders in hyprshade config

### Configuration

Selected shader stored in `~/.config/ml4w/settings/hyprshade.sh`:

```bash
hyprshade_filter="blue-light-filter-50"
```

### Example Keybinding

```ini
# Toggle shader
bind = $mainMod SHIFT, S, exec, ~/.config/hypr/scripts/hyprshade.sh

# Select shader
bind = $mainMod SHIFT ALT, S, exec, ~/.config/hypr/scripts/hyprshade.sh rofi
```

## Game Mode (gamemode.sh)

**Location:** `~/.config/hypr/scripts/gamemode.sh`

Toggle performance mode by disabling visual effects.

### Usage

```bash
~/.config/hypr/scripts/gamemode.sh
```

### What It Disables

| Setting | Game Mode Value |
|---------|-----------------|
| `animations:enabled` | 0 |
| `decoration:shadow:enabled` | 0 |
| `decoration:blur:enabled` | 0 |
| `general:gaps_in` | 0 |
| `general:gaps_out` | 0 |
| `general:border_size` | 1 |
| `decoration:rounding` | 0 |

### Behavior

- Toggle on: Creates `~/.config/ml4w/settings/gamemode-enabled` flag
- Toggle off: Removes flag and runs `hyprctl reload` to restore settings

### Example Keybinding

```ini
bind = $mainMod ALT, G, exec, ~/.config/hypr/scripts/gamemode.sh
```

## Toggle Animations (toggle-animations.sh)

**Location:** `~/.config/hypr/scripts/toggle-animations.sh`

Quick toggle for animations only.

### Usage

```bash
~/.config/hypr/scripts/toggle-animations.sh
```

### Behavior

- Uses `~/.cache/toggle_animation` as toggle flag
- Won't toggle if `disabled.conf` animation variation is active

### Example Keybinding

```ini
bind = $mainMod SHIFT, A, exec, ~/.config/hypr/scripts/toggle-animations.sh
```

## GTK Theme Sync (gtk.sh)

**Location:** `~/.config/hypr/scripts/gtk.sh`

Synchronize GTK settings from config files to gsettings.

### Usage

```bash
~/.config/hypr/scripts/gtk.sh
```

### What It Syncs

From `~/.config/gtk-3.0/settings.ini`:
- GTK theme
- Icon theme
- Cursor theme and size
- Font name
- Dark/light preference

### Also Configures

- Hyprland cursor settings
- Nautilus terminal integration

### Auto-Run

This script runs automatically on Hyprland startup via autostart.conf.

## Related

- [02-DESKTOP-CONTROL](./02-DESKTOP-CONTROL.md) - Power and screenshot scripts
- [05-UTILITIES](./05-UTILITIES.md) - System utilities
- [../desktop/05-THEMING](../desktop/05-THEMING.md) - Theme configuration
