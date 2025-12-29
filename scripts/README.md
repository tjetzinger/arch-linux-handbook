# Scripts

Custom scripts for Hyprland and ML4W desktop environment.

## Contents

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | Script inventory and categories |
| [02-DESKTOP-CONTROL](./02-DESKTOP-CONTROL.md) | Power, screenshots, system control |
| [03-WALLPAPER-THEMING](./03-WALLPAPER-THEMING.md) | Wallpaper and visual effects |
| [04-MONITORS](./04-MONITORS.md) | Monitor management scripts |
| [05-UTILITIES](./05-UTILITIES.md) | Config reload, GTK, XDG |
| [06-SYSTEM-MAINTENANCE](./06-SYSTEM-MAINTENANCE.md) | Updates, snapshots, cleanup |
| [07-WAYBAR-INTEGRATION](./07-WAYBAR-INTEGRATION.md) | Scripts for Waybar modules |
| [08-CUSTOMIZATION](./08-CUSTOMIZATION.md) | Creating new scripts |

## Script Locations

| Directory | Purpose |
|-----------|---------|
| `~/.config/hypr/scripts/` | Hyprland desktop scripts (26) |
| `~/.config/ml4w/scripts/` | ML4W utility scripts (11) |
| `~/.config/ml4w/scripts/arch/` | Arch-specific scripts (7) |

## Quick Reference

### Common Keybindings

| Key | Script | Action |
|-----|--------|--------|
| `Super+Ctrl+L` | power.sh | Lock screen |
| `Super+P` | screenshot.sh | Screenshot |
| `Super+Shift+A` | toggle-animations.sh | Toggle animations |
| `Super+Shift+H` | hyprshade.sh | Toggle shader |
| `Super+Alt+G` | gamemode.sh | Toggle game mode |
| `Super+Ctrl+K` | keybindings.sh | Show keybindings |
| `Super+Shift+R` | loadconfig.sh | Reload config |

### Run Script Directly

```bash
# Hyprland scripts
~/.config/hypr/scripts/screenshot.sh
~/.config/hypr/scripts/wallpaper.sh /path/to/image.jpg

# ML4W scripts
~/.config/ml4w/scripts/updates.sh
~/.config/ml4w/scripts/arch/snapshot.sh
```

### Check Available Scripts

```bash
ls ~/.config/hypr/scripts/
ls ~/.config/ml4w/scripts/
```

## Categories

### Desktop Control
- power.sh - Lock, suspend, shutdown
- screenshot.sh - Screen capture

### Wallpaper & Theming
- wallpaper.sh - Set wallpaper with color generation
- hyprshade.sh - Color filters/shaders
- gamemode.sh - Performance mode

### Monitor Management
- toggle-monitors.sh - Dock/undock switching
- lid-switch-monitor.sh - Laptop lid handling

### System Maintenance
- installupdates.sh - System updates
- snapshot.sh - Create snapshots
- cleanup.sh - Cache cleanup

## Related

- [../desktop/](../desktop/) - Desktop configuration
- [../desktop/03-KEYBINDINGS](../desktop/03-KEYBINDINGS.md) - Full keybinding reference
