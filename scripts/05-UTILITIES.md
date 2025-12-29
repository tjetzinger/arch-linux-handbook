# 05 - System Utility Scripts

Configuration reload, XDG portal, and system integration scripts.

## XDG Portal Setup (xdg.sh)

**Location:** `~/.config/hypr/scripts/xdg.sh`

Initialize XDG desktop portals for Wayland/Hyprland compatibility.

### Purpose

XDG portals are required for:
- Screen sharing (OBS, Discord, Zoom)
- File picker dialogs
- Application sandboxing (Flatpak)
- Proper desktop integration

### Usage

```bash
~/.config/hypr/scripts/xdg.sh
```

### What It Does

1. **Kills existing portals**
   - xdg-desktop-portal-hyprland
   - xdg-desktop-portal-gnome
   - xdg-desktop-portal-kde
   - xdg-desktop-portal-wlr
   - xdg-desktop-portal-gtk
   - xdg-desktop-portal

2. **Sets environment**
   ```bash
   dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland
   ```

3. **Restarts services**
   - Stops pipewire, wireplumber
   - Starts xdg-desktop-portal-hyprland
   - Starts xdg-desktop-portal-gtk (if available)
   - Starts xdg-desktop-portal
   - Restarts pipewire, wireplumber

4. **Launches waybar**

### Auto-Run

This script runs automatically on Hyprland startup.

### Troubleshooting Screen Sharing

If screen sharing doesn't work:

```bash
# Check portal status
systemctl --user status xdg-desktop-portal
systemctl --user status xdg-desktop-portal-hyprland

# Manually restart
~/.config/hypr/scripts/xdg.sh
```

## Config Reload (loadconfig.sh)

**Location:** `~/.config/hypr/scripts/loadconfig.sh`

Reload Hyprland configuration.

### Usage

```bash
~/.config/hypr/scripts/loadconfig.sh
```

### What It Does

```bash
hyprctl reload
```

### When to Use

After editing:
- `~/.config/hypr/hyprland.conf`
- Any file in `~/.config/hypr/conf/`
- Keybindings, window rules, etc.

### Example Keybinding

```ini
bind = $mainMod SHIFT, R, exec, ~/.config/hypr/scripts/loadconfig.sh
```

## GTK Settings Sync (gtk.sh)

**Location:** `~/.config/hypr/scripts/gtk.sh`

Synchronize GTK3 settings to GNOME gsettings for application consistency.

### Usage

```bash
~/.config/hypr/scripts/gtk.sh
```

### Settings Synced

From `~/.config/gtk-3.0/settings.ini`:

| GTK Setting | gsettings Key |
|-------------|---------------|
| gtk-theme-name | gtk-theme |
| gtk-icon-theme-name | icon-theme |
| gtk-cursor-theme-name | cursor-theme |
| gtk-font-name | font-name |
| gtk-application-prefer-dark-theme | color-scheme |

### Also Configures

1. **Hyprland Cursor**
   - Writes to `~/.config/hypr/conf/cursor.conf`
   - Sets cursor with `hyprctl setcursor`

2. **Nautilus Terminal Integration**
   ```bash
   gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal "$terminal"
   ```

### Auto-Run

Runs on Hyprland startup to ensure GTK apps match theme.

## Cleanup (cleanup.sh)

**Location:** `~/.config/hypr/scripts/cleanup.sh`

Startup cleanup for stale state files.

### Usage

```bash
~/.config/hypr/scripts/cleanup.sh
```

### What It Cleans

- `~/.cache/gamemode` - Stale gamemode flag

### Auto-Run

Runs on Hyprland startup.

## Restart Hypridle (restart-hypridle.sh)

**Location:** `~/.config/hypr/scripts/restart-hypridle.sh`

Restart the hypridle screen lock daemon.

### Usage

```bash
~/.config/hypr/scripts/restart-hypridle.sh
```

### What It Does

```bash
killall hypridle
sleep 1
hypridle &
notify-send "hypridle has been restarted."
```

### When to Use

After changing hypridle configuration:
- `~/.config/hypr/hypridle.conf`

## Toggle All Float (toggleallfloat.sh)

**Location:** `~/.config/hypr/scripts/toggleallfloat.sh`

Toggle all windows between tiled and floating.

### Usage

```bash
~/.config/hypr/scripts/toggleallfloat.sh
```

## Disable Display Manager (disabledm.sh)

**Location:** `~/.config/hypr/scripts/disabledm.sh`

Disable SDDM for TTY-based login.

### Usage

```bash
~/.config/hypr/scripts/disabledm.sh
```

### What It Does

1. Disables SDDM service
2. Enables TTY login
3. Configures auto-start Hyprland from shell

### Use Case

- Multi-monitor issues with SDDM
- Faster boot without display manager
- Preferred TTY workflow

## Microphone Fix (fix-microphone.sh)

**Location:** `~/.local/bin/fix-microphone.sh`

Fix microphone configuration issues.

### Usage

```bash
~/.local/bin/fix-microphone.sh
```

### What It Does

```bash
# Set microphone boost
amixer -c 0 sset "Mic Boost" 2

# Set default source
wpctl set-default 33
# or
pactl set-default-source alsa_input.pci-0000_00_1f.3.analog-stereo
```

### Note

Device IDs may vary - edit script for your hardware.

## Script Dependencies

| Script | Dependencies |
|--------|--------------|
| xdg.sh | systemctl, dbus, pipewire, wireplumber |
| loadconfig.sh | hyprctl |
| gtk.sh | gsettings, hyprctl |
| cleanup.sh | none |
| restart-hypridle.sh | hypridle, notify-send |
| fix-microphone.sh | amixer, wpctl/pactl |

## Related

- [02-DESKTOP-CONTROL](./02-DESKTOP-CONTROL.md) - Power management
- [03-WALLPAPER-THEMING](./03-WALLPAPER-THEMING.md) - Theme scripts
- [../desktop/02-HYPRLAND-CONFIG](../desktop/02-HYPRLAND-CONFIG.md) - Hyprland configuration
