# 08 - Lock Screen

swaylock-effects and swayidle configuration for Niri.

## Overview

| Component | Purpose |
|-----------|---------|
| swaylock-effects | Lock screen (visual + auth) |
| swayidle | Idle management (triggers) |

## swayidle

Daemon that triggers actions based on idle time. Managed by `~/.config/niri-setup/scripts/swayidle.sh`.

### Configuration

**File:** `~/.config/niri-setup/scripts/swayidle.sh`

The script reads idle timeout from `~/.local/state/idle-time` and launches swayidle with matching timeouts:

| idle-time value | Lock | DPMS off | Suspend |
|-----------------|------|----------|---------|
| 5 minutes | 300s | 420s | 1800s |
| 10 minutes (default) | 600s | 720s | 1800s |
| 20 minutes | 1200s | 1500s | 2400s |
| 30 minutes | 1800s | 2100s | 3600s |
| infinity | disabled | disabled | disabled |

### Changing Idle Timeout

```bash
# Set idle time (persists across reboots)
echo "20 minutes" > ~/.local/state/idle-time

# Restart swayidle
pkill swayidle
~/.config/niri-setup/scripts/swayidle.sh &
```

Valid values: `5 minutes`, `10 minutes`, `20 minutes`, `30 minutes`, `infinity`

### Manual Control

```bash
# Check if running
pgrep -a swayidle

# Restart
pkill swayidle && ~/.config/niri-setup/scripts/swayidle.sh &
```

## swaylock-effects

Lock screen with blur, clock, and vignette effects.

### Configuration

**File:** `~/.config/niri-setup/scripts/swaylock.sh`

The script prevents duplicate locks (ext-session-lock-v1 only allows one client) and launches swaylock with visual settings:

```bash
swaylock \
  --daemonize \
  --clock \
  --screenshots \
  --ignore-empty-password \
  --font "Ubuntu Bold" \
  --indicator \
  --indicator-radius 150 \
  --effect-scale 0.4 \
  --effect-vignette 0.2:0.5 \
  --effect-blur 4x2 \
  --datestr "%A, %b %d" \
  --timestr "%k:%M"
```

### Lock Screen Manually

```bash
# Via keybinding (preferred)
# Mod + L

# Via script
~/.config/niri-setup/scripts/swaylock.sh

# Via session
loginctl lock-session
```

### Fingerprint Limitation

swaylock-effects only initiates PAM authentication when Enter is pressed (password submission). It does not start fingerprint listening in the background on lock. Fingerprint unlock on the lock screen would require `swaylock-fprintd` (AUR: `swaylock-fprintd-git`), a fork with native fprintd integration.

Fingerprint auth works for sudo, polkit, and login -- see [../hardware/07-BIOMETRICS.md](../hardware/07-BIOMETRICS.md).

## Keybindings

| Key | Action |
|-----|--------|
| `Mod + L` | Lock screen |

Defined in `~/.config/niri/binds.kdl`:

```kdl
Mod+L { spawn-sh "$NIRICONF/scripts/swaylock.sh"; }
```

## Troubleshooting

### Lock Screen Not Triggering

```bash
# Check swayidle
pgrep -a swayidle

# Check current idle time setting
cat ~/.local/state/idle-time

# Restart swayidle
pkill swayidle && ~/.config/niri-setup/scripts/swayidle.sh &
```

### Can't Unlock

```bash
# Check PAM configuration
cat /etc/pam.d/swaylock

# Force kill (from another TTY: Ctrl+Alt+F2)
killall swaylock
```

### Display Stays Off After Wake

```bash
# Move mouse or press a key
# Niri should restore monitors automatically

# Force monitors on
niri msg action power-on-monitors
```

## Quick Reference

```bash
# Lock screen
~/.config/niri-setup/scripts/swaylock.sh
loginctl lock-session

# Check swayidle
pgrep -a swayidle

# Change idle timeout
echo "20 minutes" > ~/.local/state/idle-time

# Restart swayidle
pkill swayidle && ~/.config/niri-setup/scripts/swayidle.sh &

# Monitor control
niri msg action power-off-monitors
niri msg action power-on-monitors

# Config files
~/.config/niri-setup/scripts/swaylock.sh   # Lock screen appearance
~/.config/niri-setup/scripts/swayidle.sh   # Idle timeout management
/etc/pam.d/swaylock                        # Authentication
~/.config/niri/binds.kdl                   # Keybinding
```

## Related

- [../hardware/07-BIOMETRICS.md](../hardware/07-BIOMETRICS.md) - Fingerprint setup and enrollment
- [09-THEMING](./09-THEMING.md) - Desktop theming
