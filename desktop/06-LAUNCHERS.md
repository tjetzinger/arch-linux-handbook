# 06 - Launchers

Application launchers and menus.

## Rofi

Application launcher and menu system.

### Launch

```bash
# Application launcher
rofi -show drun -replace -i

# Or keybinding
# Super + Ctrl + Return
```

### Configuration

**Directory:** `~/.config/rofi/`

```
~/.config/rofi/
├── config.rasi              # Main config
├── colors.rasi              # Pywal colors
├── config-cliphist.rasi     # Clipboard config
├── config-screenshot.rasi   # Screenshot menu
├── config-themes.rasi       # Theme selector
└── ...
```

### Modes

| Mode | Description |
|------|-------------|
| drun | Application launcher (.desktop files) |
| run | Command runner |
| window | Window switcher |
| ssh | SSH connections |
| filebrowser | File browser |

### Keybindings

| Key | Action |
|-----|--------|
| `Super + Ctrl + Return` | Application launcher |
| `Super + V` | Clipboard (cliphist) |

### Example Config

**File:** `~/.config/rofi/config.rasi`

```css
configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    drun-display-format: "{name}";
    scroll-method: 0;
    disable-history: false;
    sidebar-mode: true;
}

@theme "~/.config/rofi/themes/current.rasi"
@import "~/.config/rofi/colors.rasi"
```

### Custom Menus

ML4W provides several Rofi menus:

```bash
# Screenshot menu
rofi -show screenshot -config ~/.config/rofi/config-screenshot.rasi

# Theme selector
rofi -show themes -config ~/.config/rofi/config-themes.rasi
```

## Clipboard Manager (cliphist)

Clipboard history with Rofi interface.

### Usage

```bash
# Open clipboard history
~/.config/ml4w/scripts/cliphist.sh

# Or keybinding
# Super + V
```

### How It Works

1. `wl-paste --watch cliphist store` runs at startup
2. Stores clipboard entries in database
3. Rofi displays history for selection

### Clear History

```bash
cliphist wipe
```

### Configuration

**File:** `~/.config/rofi/config-cliphist.rasi`

## Emoji Picker

```bash
# Open emoji picker
~/.config/ml4w/settings/emojipicker.sh

# Or keybinding
# Super + Ctrl + E
```

## Calculator

```bash
# Open calculator
~/.config/ml4w/settings/calculator.sh

# Or keybinding
# Super + Ctrl + C
```

## wlogout

Logout/power menu.

### Launch

```bash
~/.config/ml4w/scripts/wlogout.sh

# Or keybinding
# Super + Ctrl + Q
```

### Options

| Button | Action |
|--------|--------|
| Lock | Lock screen |
| Logout | End session |
| Suspend | Suspend |
| Hibernate | Hibernate |
| Shutdown | Power off |
| Reboot | Restart |

### Configuration

**File:** `~/.config/wlogout/layout`

## nwg-dock

Application dock at bottom of screen.

### Location

```
~/.config/nwg-dock-hyprland/
├── launch.sh
├── style.css
└── colors.css
```

### Launch

Started automatically via autostart:

```bash
exec-once = ~/.config/nwg-dock-hyprland/launch.sh
```

### Customization

Edit `style.css` for appearance changes.

## Quick Reference

```bash
# Application launcher
rofi -show drun -i

# Clipboard history
cliphist list | rofi -dmenu | cliphist decode | wl-copy

# Logout menu
~/.config/ml4w/scripts/wlogout.sh

# Emoji picker
~/.config/ml4w/settings/emojipicker.sh
```

## Related

- [03-KEYBINDINGS](./03-KEYBINDINGS.md) - Launcher shortcuts
- [09-THEMING](./09-THEMING.md) - Rofi themes
