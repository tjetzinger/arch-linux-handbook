# 02 - Desktop Control Scripts

Power management and screenshot capture scripts.

## Power Management (power.sh)

**Location:** `~/.config/hypr/scripts/power.sh`

### Usage

```bash
~/.config/hypr/scripts/power.sh [action]
```

### Actions

| Action | Description | Command |
|--------|-------------|---------|
| `lock` | Lock screen with hyprlock | `power.sh lock` |
| `suspend` | Suspend to RAM | `power.sh suspend` |
| `hibernate` | Hibernate to disk | `power.sh hibernate` |
| `reboot` | Reboot system | `power.sh reboot` |
| `shutdown` | Power off | `power.sh shutdown` |
| `exit` | Exit Hyprland | `power.sh exit` |

### Client Termination

Before shutdown/reboot/exit, the script gracefully terminates all Hyprland clients:
1. Gets list of all client PIDs via `hyprctl clients -j`
2. Sends SIGTERM (kill -15) to each process
3. Waits up to 5 seconds for graceful shutdown
4. Proceeds with power action

### Example Keybindings

```ini
# In ~/.config/hypr/conf/keybinding.conf
bind = $mainMod CTRL, L, exec, ~/.config/hypr/scripts/power.sh lock
bind = $mainMod SHIFT, X, exec, ~/.config/hypr/scripts/power.sh exit
```

## Screenshot (screenshot.sh)

**Location:** `~/.config/hypr/scripts/screenshot.sh`

### Features

- Interactive rofi menu for screenshot options
- Multiple capture modes (full screen, active display, selection)
- Delayed capture (5s to 60s countdown)
- Copy, save, or edit options
- Uses grimblast for Wayland-native capture

### Usage

```bash
~/.config/hypr/scripts/screenshot.sh
```

Opens rofi menu with options:

### Menu Flow

```
1. Immediate / Delayed
   ↓
2. Capture Everything / Active Display / Selection
   ↓
3. Copy / Save / Copy & Save / Edit
```

### Configuration

Screenshots are configured via:

```bash
# Screenshot filename format
~/.config/ml4w/settings/screenshot-filename.sh

# Screenshot save folder
~/.config/ml4w/settings/screenshot-folder.sh

# Screenshot editor
~/.config/ml4w/settings/screenshot-editor.sh
```

### Default Behavior

- Screenshots saved to `~/Screenshots/` (configurable via XDG_SCREENSHOTS_DIR)
- Moved from `$HOME` to screenshot folder after capture
- Filename based on settings file

### Dependencies

- `grimblast` - Screenshot utility
- `rofi` - Menu interface
- `notify-send` - Desktop notifications

### Example Keybindings

```ini
# Interactive screenshot menu
bind = $mainMod, P, exec, ~/.config/hypr/scripts/screenshot.sh

# Direct screenshot commands
bind = , Print, exec, grimblast save screen
bind = SHIFT, Print, exec, grimblast save area
bind = ALT, Print, exec, grimblast save output
```

## Keybindings Viewer (keybindings.sh)

**Location:** `~/.config/hypr/scripts/keybindings.sh`

Displays current keybindings in a rofi menu for quick reference.

### Usage

```bash
~/.config/hypr/scripts/keybindings.sh
```

### How It Works

1. Reads keybinding config from `~/.config/hypr/conf/keybinding.conf`
2. Parses `bind =` lines with awk
3. Replaces `$mainMod` with "SUPER"
4. Displays in rofi with searchable format

### Example Keybinding

```ini
bind = $mainMod CTRL, K, exec, ~/.config/hypr/scripts/keybindings.sh
```

## System Info (systeminfo.sh)

**Location:** `~/.config/hypr/scripts/systeminfo.sh`

Displays Hyprland system information in terminal.

### Usage

```bash
~/.config/hypr/scripts/systeminfo.sh
```

### Output

Shows figlet banner and `hyprctl systeminfo` output including:
- Hyprland version
- Wayland socket
- GPU information
- Monitor configuration

## Hypridle Toggle (hypridle.sh)

**Location:** `~/.config/hypr/scripts/hypridle.sh`

Controls the hypridle screen lock daemon.

### Usage

```bash
# Toggle hypridle on/off
~/.config/hypr/scripts/hypridle.sh toggle

# Get status (JSON for waybar)
~/.config/hypr/scripts/hypridle.sh status
```

### Waybar Integration

The `status` action outputs JSON for waybar modules:

```json
{"text": "RUNNING", "class": "active", "tooltip": "Screen locking active"}
```

### Waybar Module Config

```json
"custom/hypridle": {
    "exec": "~/.config/hypr/scripts/hypridle.sh status",
    "on-click": "~/.config/hypr/scripts/hypridle.sh toggle",
    "return-type": "json",
    "interval": 5
}
```

## Related

- [03-WALLPAPER-THEMING](./03-WALLPAPER-THEMING.md) - Wallpaper and visual effects
- [04-MONITORS](./04-MONITORS.md) - Monitor management
- [../desktop/03-KEYBINDINGS](../desktop/03-KEYBINDINGS.md) - Full keybinding reference
