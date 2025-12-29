# 10 - Terminals

Terminal emulator configuration - Warp (primary) and Kitty (backup).

## Current Default

**Warp Terminal** is the configured default.

```bash
cat ~/.config/ml4w/settings/terminal.sh
# warp-terminal
```

## Warp Terminal

Modern terminal with AI features.

### Launch

```bash
warp-terminal

# Or keybinding
# Super + Return
```

### Configuration

**File:** `~/.config/warp-terminal/user_preferences.json`

### Key Settings

| Setting | Value |
|---------|-------|
| Font Size | 15.0 |
| Opacity | 57% |
| Vim Mode | Enabled |
| Zoom | 100% |

### Features

- **AI Assistant** - Command suggestions and explanations
- **Vim Mode** - Modal editing in command line
- **Blocks** - Command output grouping
- **Workflows** - Saved command sequences
- **SSH Integration** - Uses tmux wrapper

### Vim Mode

Enabled in preferences:

```json
"VimModeEnabled": "true"
```

Toggle with `Ctrl+Shift+V` in Warp.

### Transparency

```json
"OverrideOpacity": "57"
```

### SSH

Warp uses tmux wrapper for SSH sessions:

```json
"UseSshTmuxWrapper": "true"
```

## Kitty (Backup)

GPU-accelerated terminal emulator.

### Installation

Already installed:

```bash
which kitty
# /usr/bin/kitty
```

### Configuration

**Directory:** `~/.config/kitty/`

```
~/.config/kitty/
├── kitty.conf              # Main config
├── custom.conf             # Custom overrides
├── colors.conf             # Pywal colors
├── current-theme.conf      # Active theme
└── Catppuccin-Macchiato.conf  # Theme file
```

### Main Settings

**File:** `~/.config/kitty/kitty.conf`

```bash
font_family                 JetBrainsMono Nerd Font
font_size                   12
remember_window_size        no
initial_window_width        950
initial_window_height       500
cursor_blink_interval       0.5
scrollback_lines            2000
enable_audio_bell           no
window_padding_width        10
hide_window_decorations     yes
background_opacity          0.7
dynamic_background_opacity  yes
confirm_os_window_close     0
```

### Custom Config

**File:** `~/.config/kitty/custom.conf`

Add your customizations here:

```bash
# Example: Change font size
font_size 14

# Example: Different opacity
background_opacity 0.8
```

### Launch Kitty

```bash
kitty
```

### Kitty Commands

```bash
# New tab
Ctrl+Shift+T

# New window
Ctrl+Shift+Enter

# Close window
Ctrl+Shift+W

# Scroll up/down
Ctrl+Shift+Up/Down

# Change font size
Ctrl+Shift+Plus/Minus

# Reset font size
Ctrl+Shift+Backspace
```

### Themes

Catppuccin is pre-configured:

```bash
include ./Catppuccin-Macchiato.conf
```

### Pywal Integration

In `kitty.conf`:

```bash
# Uncomment to use pywal colors
#include $HOME/.cache/wal/colors-kitty.conf
```

## Switching Default Terminal

### Via ML4W Settings

```bash
ml4w-hyprland-settings
```

Navigate to terminal settings.

### Manual Change

Edit `~/.config/ml4w/settings/terminal.sh`:

```bash
# For Warp
warp-terminal

# For Kitty
kitty
```

## Terminal Features Comparison

| Feature | Warp | Kitty |
|---------|------|-------|
| GPU Acceleration | Yes | Yes |
| AI Integration | Yes | No |
| Vim Mode | Yes | Partial |
| Multiplexing | Built-in | Via tabs |
| Configuration | JSON | Plain text |
| Transparency | Yes | Yes |
| Ligatures | Yes | Yes |
| Image Display | Yes | Yes |

## Common Environment

Both terminals respect these environment variables:

```bash
# In ~/.config/hypr/conf/custom.conf or shell profile
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=warp-terminal
```

## Floating Terminal

For dropdown/floating terminal windows:

```bash
# Kitty with specific class
kitty --class floating-terminal

# Then add window rule
# windowrule = float,class:(floating-terminal)
```

## Troubleshooting

### Terminal Won't Launch

```bash
# Check if installed
which warp-terminal
which kitty

# Try running directly
warp-terminal
kitty

# Check errors
journalctl --user -n 50
```

### Font Issues

```bash
# Check if Nerd Font is installed
fc-list | grep -i "JetBrains"

# Install if missing
sudo pacman -S ttf-jetbrains-mono-nerd
```

### Transparency Not Working

```bash
# Check compositor settings
# Hyprland should handle this automatically

# Verify opacity setting in terminal config
```

## Quick Reference

```bash
# Launch default terminal
~/.config/ml4w/settings/terminal.sh

# Launch Warp
warp-terminal

# Launch Kitty
kitty

# Change default
$EDITOR ~/.config/ml4w/settings/terminal.sh

# Kitty config
$EDITOR ~/.config/kitty/kitty.conf

# Warp preferences location
~/.config/warp-terminal/user_preferences.json
```

## Related

- [03-KEYBINDINGS](./03-KEYBINDINGS.md) - Terminal keybindings
- [09-THEMING](./09-THEMING.md) - Terminal colors
