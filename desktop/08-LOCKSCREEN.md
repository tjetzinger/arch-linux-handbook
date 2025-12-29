# 08 - Lock Screen

hyprlock and hypridle configuration.

## Overview

| Component | Purpose |
|-----------|---------|
| hyprlock | Lock screen (visual) |
| hypridle | Idle management (triggers) |

## hypridle

Daemon that triggers actions based on idle time.

### Configuration

**File:** `~/.config/hypr/hypridle.conf`

```bash
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

# Lock screen after 10 minutes
listener {
    timeout = 600
    on-timeout = loginctl lock-session
}

# Turn off display after 11 minutes
listener {
    timeout = 660
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

# Suspend after 30 minutes
listener {
    timeout = 1800
    on-timeout = systemctl suspend
}
```

### Current Timeouts

| Event | Timeout |
|-------|---------|
| Lock screen | 10 minutes (600s) |
| DPMS off | 11 minutes (660s) |
| Suspend | 30 minutes (1800s) |

### Service

Started automatically via autostart:

```bash
exec-once = hypridle
```

### Manual Control

```bash
# Check if running
pgrep hypridle

# Restart
killall hypridle && hypridle &
```

## hyprlock

Lock screen application.

### Configuration

**File:** `~/.config/hypr/hyprlock.conf`

```bash
general {
    disable_loading_bar = false
    hide_cursor = true
    grace = 0
    no_fade_in = false
}

background {
    monitor =
    path = screenshot
    blur_passes = 3
    blur_size = 8
}

input-field {
    monitor =
    size = 200, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = true
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = true
    placeholder_text = <i>Password...</i>
    hide_input = false
    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    color = rgba(200, 200, 200, 1.0)
    font_size = 50
    font_family = JetBrainsMono Nerd Font
    position = 0, 80
    halign = center
    valign = center
}
```

### Lock Screen Manually

```bash
hyprlock

# Or via keybinding
# Super + Ctrl + L
```

### Lock via Session

```bash
loginctl lock-session
```

## Keybindings

| Key | Action |
|-----|--------|
| `Super + Ctrl + L` | Lock screen |
| `Super + Ctrl + Q` | Logout menu (includes lock) |
| `XF86Lock` | Lock screen (keyboard key) |

## ML4W Settings

Timeouts can be adjusted via ML4W Settings:

```
~/.config/ml4w/settings/
├── hypridle_dpms_timeout.sh
├── hypridle_hyprlock_timeout.sh
└── hypridle_suspend_timeout.sh
```

Or use:

```bash
ml4w-hyprland-settings
```

## Customization

### Background

Options in hyprlock.conf:

```bash
background {
    # Screenshot with blur
    path = screenshot
    blur_passes = 3
    blur_size = 8

    # Or static image
    # path = ~/.config/hypr/wallpaper.png

    # Or solid color
    # color = rgba(25, 20, 20, 1.0)
}
```

### Input Field

```bash
input-field {
    size = 200, 50
    outline_thickness = 3
    dots_size = 0.33
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    placeholder_text = <i>Password...</i>
}
```

### Clock/Labels

```bash
label {
    text = $TIME          # Current time
    # text = cmd[update:1000] date +"%H:%M:%S"  # Custom format
    font_size = 50
    font_family = JetBrainsMono Nerd Font
    position = 0, 80
    halign = center
    valign = center
}
```

### Available Variables

| Variable | Description |
|----------|-------------|
| `$TIME` | Current time |
| `$USER` | Username |
| `cmd[update:ms] command` | Dynamic command |

## Fingerprint Authentication

If fprintd is configured, hyprlock can use fingerprint:

```bash
# Ensure PAM is configured
cat /etc/pam.d/hyprlock

# Should include:
# auth sufficient pam_fprintd.so
```

See [../hardware/07-BIOMETRICS.md](../hardware/07-BIOMETRICS.md).

## Troubleshooting

### Lock Screen Not Triggering

```bash
# Check hypridle
pgrep hypridle

# Check idle time
# (should trigger at configured timeout)
```

### Can't Unlock

```bash
# Try password first
# Check PAM configuration
cat /etc/pam.d/hyprlock

# Force kill (from TTY)
# Ctrl+Alt+F2, login, then:
killall hyprlock
```

### Display Stays Off

```bash
# DPMS should turn on after wake
# If stuck, move mouse or press key

# Force DPMS on
hyprctl dispatch dpms on
```

## Quick Reference

```bash
# Lock screen
hyprlock
loginctl lock-session

# Check hypridle
pgrep hypridle

# DPMS control
hyprctl dispatch dpms off
hyprctl dispatch dpms on

# Config files
~/.config/hypr/hyprlock.conf
~/.config/hypr/hypridle.conf
```

## Related

- [../hardware/07-BIOMETRICS.md](../hardware/07-BIOMETRICS.md) - Fingerprint unlock
- [09-THEMING](./09-THEMING.md) - Lock screen theming
