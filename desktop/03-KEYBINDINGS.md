# 03 - Keybindings

Keyboard shortcuts for Hyprland with ML4W configuration.

## Modifier Key

The main modifier is **Super** (Windows key).

```bash
$mainMod = SUPER
```

## Application Launchers

| Keybinding | Action |
|------------|--------|
| `Super + Return` | Open terminal (Warp) |
| `Super + Ctrl + Return` | Application launcher (Rofi) |
| `Super + B` | Open browser |
| `Super + E` | Open file manager |
| `Super + Ctrl + E` | Emoji picker |
| `Super + Ctrl + C` | Calculator |
| `Super + V` | Clipboard history (cliphist) |

## Window Management

### Basic Controls

| Keybinding | Action |
|------------|--------|
| `Super + Q` | Close window |
| `Super + Shift + Q` | Kill application (all instances) |
| `Super + F` | Fullscreen |
| `Super + M` | Maximize |
| `Super + T` | Toggle floating |
| `Super + Shift + T` | Float all windows |
| `Super + J` | Toggle split direction |
| `Super + K` | Swap split |
| `Super + G` | Toggle window group |

### Focus Movement

| Keybinding | Action |
|------------|--------|
| `Super + ←` | Focus left |
| `Super + →` | Focus right |
| `Super + ↑` | Focus up |
| `Super + ↓` | Focus down |
| `Alt + Tab` | Cycle windows |

### Window Resize

| Keybinding | Action |
|------------|--------|
| `Super + Shift + →` | Increase width |
| `Super + Shift + ←` | Decrease width |
| `Super + Shift + ↓` | Increase height |
| `Super + Shift + ↑` | Decrease height |

### Window Swap

| Keybinding | Action |
|------------|--------|
| `Super + Alt + ←` | Swap left |
| `Super + Alt + →` | Swap right |
| `Super + Alt + ↑` | Swap up |
| `Super + Alt + ↓` | Swap down |

### Mouse Bindings

| Keybinding | Action |
|------------|--------|
| `Super + Left Click` | Move window |
| `Super + Right Click` | Resize window |
| `Super + Scroll Up` | Previous workspace |
| `Super + Scroll Down` | Next workspace |

## Workspaces

Using **split-monitor-workspaces** plugin for per-monitor workspaces.

### Switch Workspace

| Keybinding | Action |
|------------|--------|
| `Super + 1-0` | Go to workspace 1-10 |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |
| `Super + Ctrl + ↓` | First empty workspace |

### Move Window to Workspace

| Keybinding | Action |
|------------|--------|
| `Super + Shift + 1-0` | Move window to workspace 1-10 |

### Move All Windows

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + 1-0` | Move all windows to workspace 1-10 |

### Multi-Monitor

| Keybinding | Action |
|------------|--------|
| `Super + Alt + ,` | Move window to previous monitor |
| `Super + Alt + .` | Move window to next monitor |

## System Actions

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + R` | Reload Hyprland |
| `Super + Shift + R` | Reload config (full) |
| `Super + Ctrl + Q` | Logout menu (wlogout) |
| `Super + Ctrl + L` | Lock screen |

## Screenshots

| Keybinding | Action |
|------------|--------|
| `Super + Print` | Screenshot |
| `Super + Shift + S` | Screenshot (region) |

## Waybar

| Keybinding | Action |
|------------|--------|
| `Super + Shift + B` | Reload Waybar |
| `Super + Ctrl + B` | Toggle Waybar |
| `Super + Ctrl + T` | Waybar theme switcher |

## Wallpaper

| Keybinding | Action |
|------------|--------|
| `Super + Shift + W` | Random wallpaper |
| `Super + Ctrl + W` | Wallpaper selector (waypaper) |
| `Super + Alt + W` | Wallpaper automation |

## Visual Effects

| Keybinding | Action |
|------------|--------|
| `Super + Shift + A` | Toggle animations |
| `Super + Shift + H` | Toggle screen shader |
| `Super + Alt + G` | Game mode (disable effects) |

## ML4W Settings

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + S` | ML4W Settings app |
| `Super + Ctrl + K` | Show keybindings |

## Function Keys

| Key | Action |
|-----|--------|
| `XF86MonBrightnessUp` | Brightness +10% |
| `XF86MonBrightnessDown` | Brightness -10% |
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume -5% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle microphone |
| `XF86AudioPlay` | Play/Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86Calculator` | Calculator |
| `XF86Lock` | Lock screen |

## Configuration

### Keybinding File

**File:** `~/.config/hypr/conf/keybindings/custom.conf`

### Syntax

```bash
# Basic bind
bind = $mainMod, key, action

# With additional modifiers
bind = $mainMod SHIFT, key, action
bind = $mainMod CTRL, key, action
bind = $mainMod ALT, key, action

# Execute command
bind = $mainMod, key, exec, command

# Mouse binding
bindm = $mainMod, mouse:272, movewindow
```

### Adding Custom Keybindings

Edit `~/.config/hypr/conf/custom.conf`:

```bash
# Example: Open htop with Super+H
bind = $mainMod, H, exec, warp-terminal -e htop
```

### Show All Keybindings

```bash
# Built-in keybindings viewer
~/.config/hypr/scripts/keybindings.sh

# Or press
# Super + Ctrl + K
```

## Quick Reference

### Most Used

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal |
| `Super + Q` | Close |
| `Super + Ctrl + Return` | App launcher |
| `Super + 1-5` | Workspaces |
| `Super + F` | Fullscreen |
| `Super + T` | Float |
| `Super + V` | Clipboard |
| `Super + Ctrl + Q` | Logout |

## Related

- [02-CONFIGURATION](./02-CONFIGURATION.md) - Config files
- [11-CUSTOMIZATION](./11-CUSTOMIZATION.md) - Adding keybindings
