# 04 - Monitors

Display configuration and multi-monitor setup.

## Current Display

```bash
hyprctl monitors
```

**Internal Display:** AU Optronics 0xD291
- Resolution: 1920x1200 @ 60Hz
- Connection: eDP-1

## Monitor Configuration

### Config Location

**Generated file:** `~/.config/hypr/monitors.conf`

hyprdynamicmonitors writes monitor configuration here based on the active profile.

### Integration with Hyprland (Migration-Safe)

The default `conf/monitor.conf` is hardlinked to ML4W dotfiles and may be overwritten. To ensure hyprdynamicmonitors config is always used, source it from `custom.conf`:

**File:** `~/.config/hypr/conf/custom.conf`

```bash
# hyprdynamicmonitors generated config (overrides default monitor settings)
source = ~/.config/hypr/monitors.conf
```

This works because `custom.conf` is sourced after `monitor.conf` in `hyprland.conf`, so hyprdynamicmonitors settings take precedence.

### Manual Configuration

For manual setup without hyprdynamicmonitors:

**File:** `~/.config/hypr/conf/monitor.conf`

```bash
source = ~/.config/hypr/conf/monitors/default.conf
```

### Syntax

```bash
monitor = name, resolution@rate, position, scale

# Examples
monitor = eDP-1, 1920x1200@60, 0x0, 1
monitor = HDMI-A-1, 2560x1440@60, 1920x0, 1
monitor = , preferred, auto, 1  # Fallback for any monitor
```

## hyprdynamicmonitors

Automatic monitor profile switching based on connected displays.

### Systemd Services

Managed via systemd with autostart trigger (not direct exec-once):

```bash
# Check services
systemctl --user status hyprdynamicmonitors.service
systemctl --user status hyprdynamicmonitors-prepare.service
```

| Service | Purpose |
|---------|---------|
| `hyprdynamicmonitors.service` | Main daemon - monitors for display changes |
| `hyprdynamicmonitors-prepare.service` | Boot cleanup - prevents black screen |

**Enable both services:**

```bash
systemctl --user enable hyprdynamicmonitors.service
systemctl --user enable hyprdynamicmonitors-prepare.service
```

### Starting the Service (Migration-Safe)

The service requires `WAYLAND_DISPLAY` environment variable. Add to `autostart-custom.conf`:

```bash
# Import env so systemd services can access Hyprland socket
exec-once = systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprdynamicmonitors.service
```

This imports the Wayland environment into systemd and starts the service after Hyprland is ready.

### Service Override

**File:** `~/.config/systemd/user/hyprdynamicmonitors.service.d/override.conf`

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/hyprdynamicmonitors run --enable-lid-events
```

### Configuration

**File:** `~/.config/hyprdynamicmonitors/config.toml`

```toml
[general]
post_apply_exec = "sleep 1 && waypaper --restore"

[profiles.LaptopMode]
config_file = "hyprconfigs/LaptopMode.conf"
config_file_is_template = false

[[profiles.LaptopMode.conditions.required_monitors]]
description = "AU Optronics 0xD291"
monitor_tag = "laptop"

[profiles.DualMonitorDock]
config_file = "hyprconfigs/DualMonitorDock.go.tmpl"
config_file_type = "template"

[[profiles.DualMonitorDock.conditions.required_monitors]]
description = "BNQ BenQ BL2581T ET1CL03348SL0"
monitor_tag = "monitor1"

[[profiles.DualMonitorDock.conditions.required_monitors]]
description = "BNQ BenQ BL2581T ET1CL03342SL0"
monitor_tag = "monitor2"

# Fallback when no profile matches
[fallback_profile]
config_file = "hyprconfigs/fallback.conf"
config_file_type = "static"
```

### Profiles

| Profile | Condition |
|---------|-----------|
| LaptopMode | Only internal display connected |
| DualMonitorDock | Two BenQ monitors connected |
| Fallback | No profile matches (safety net) |

### Profile Files

```
~/.config/hyprdynamicmonitors/hyprconfigs/
├── LaptopMode.conf               # Laptop only
├── DualMonitorDock.go.tmpl       # Dock with 2 monitors (template)
├── DualMonitorDockProcessed.conf # Generated from template
└── fallback.conf                 # Generic fallback
```

**fallback.conf:**

```bash
# Configures all connected monitors with preferred settings
monitor=,preferred,auto,1
```

### Lid Events

With `--enable-lid-events`, the display automatically reconfigures when:
- Laptop lid is closed/opened
- External monitors are connected/disconnected

### Lid State Templates

Templates can conditionally disable the laptop screen when lid is closed:

**File:** `~/.config/hyprdynamicmonitors/hyprconfigs/DualMonitorDock.go.tmpl`

```go
monitor=desc:BNQ BenQ BL2581T ET1CL03348SL0,1920x1200@59.95,0x0,1
monitor=desc:BNQ BenQ BL2581T ET1CL03342SL0,1920x1200@59.95,1920x0,1
{{ if eq .LidState "Closed" }}
# Lid is closed - disable laptop screen
monitor=desc:AU Optronics 0xD291,disable
{{ else }}
# Lid is open - enable laptop screen
monitor=desc:AU Optronics 0xD291,1920x1200@60,3840x0,1
{{ end }}
```

Available template variables:
- `.LidState` - "Open" or "Closed"
- `.PowerState` - "AC" or "Battery"

## Multi-Monitor Layouts

### Extend (Side by Side)

```bash
monitor = eDP-1, 1920x1200@60, 0x0, 1
monitor = HDMI-A-1, 2560x1440@60, 1920x0, 1
```

### Mirror

```bash
monitor = HDMI-A-1, 1920x1200@60, 0x0, 1, mirror, eDP-1
```

### External Only

```bash
monitor = eDP-1, disable
monitor = HDMI-A-1, 2560x1440@60, 0x0, 1
```

### Stack (Top/Bottom)

```bash
monitor = eDP-1, 1920x1200@60, 0x1440, 1
monitor = HDMI-A-1, 2560x1440@60, 0x0, 1
```

## Workspace Assignment

Assign workspaces to specific monitors:

```bash
# In hyprland.conf or custom.conf
workspace = 1, monitor:eDP-1
workspace = 2, monitor:eDP-1
workspace = 3, monitor:HDMI-A-1
workspace = 4, monitor:HDMI-A-1
```

With split-monitor-workspaces plugin, each monitor gets its own set of workspaces automatically.

## Runtime Commands

```bash
# List monitors
hyprctl monitors

# Change monitor settings on the fly
hyprctl keyword monitor eDP-1,1920x1200@60,0x0,1

# Disable monitor
hyprctl keyword monitor eDP-1,disable

# Enable monitor
hyprctl keyword monitor eDP-1,1920x1200@60,0x0,1
```

## Scale

For HiDPI displays:

```bash
# 150% scaling
monitor = eDP-1, 1920x1200@60, 0x0, 1.5

# Integer scaling (2x)
monitor = eDP-1, 1920x1200@60, 0x0, 2
```

### XWayland Scaling

```bash
# In custom.conf
xwayland {
    force_zero_scaling = true
}

env = GDK_SCALE,2
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
```

## DPMS (Display Power)

```bash
# Turn off displays
hyprctl dispatch dpms off

# Turn on displays
hyprctl dispatch dpms on

# Turn off specific monitor
hyprctl dispatch dpms off eDP-1
```

Handled automatically by hypridle.

## Troubleshooting

### Black Screen on Boot (No External Monitors)

If you get a black screen after login when external monitors are not connected:

**Cause:** Hyprland cannot start if all monitors are disabled in the config. This happens when:
1. You used external monitors with laptop screen disabled (`monitor=eDP-1,disable`)
2. You reboot without external monitors connected
3. The old config still has the laptop screen disabled

**Solution:**

1. Enable the prepare service to clean up disabled monitors before Hyprland starts:
   ```bash
   systemctl --user enable hyprdynamicmonitors-prepare.service
   ```

2. Add a fallback profile to `~/.config/hyprdynamicmonitors/config.toml`:
   ```toml
   [fallback_profile]
   config_file = "hyprconfigs/fallback.conf"
   config_file_type = "static"
   ```

3. Create `~/.config/hyprdynamicmonitors/hyprconfigs/fallback.conf`:
   ```bash
   monitor=,preferred,auto,1
   ```

4. Ensure hyprdynamicmonitors is NOT started via exec-once (use systemd instead):
   ```bash
   # In ~/.config/hypr/conf/autostart.conf, comment out:
   # exec-once = hyprdynamicmonitors run --enable-lid-events
   ```

**Recovery if already stuck:**
- Switch to TTY with `Ctrl+Alt+F2`
- Edit monitors.conf to remove `disable` lines:
  ```bash
  echo "monitor=,preferred,auto,1" > ~/.config/hypr/monitors.conf
  ```
- Return to Hyprland with `Ctrl+Alt+F1` and reload: `hyprctl reload`

### Monitor Not Detected

```bash
# Check connected monitors
hyprctl monitors

# Check Wayland outputs
wlr-randr

# Check kernel
dmesg | grep -i drm
```

### Wrong Resolution

```bash
# List available modes
hyprctl monitors

# Force specific mode
monitor = HDMI-A-1, 2560x1440@60, 0x0, 1
```

### Flickering

```bash
# Try disabling VRR
monitor = eDP-1, 1920x1200@60, 0x0, 1, vrr, 0
```

## Niri

Niri uses `outputs.kdl` for monitor configuration. Unlike Hyprland, there is no dynamic profile switcher — the config file handles all scenarios statically.

### Config Location

**File:** `~/.config/niri/outputs.kdl`

### Identifying Monitors

```bash
niri msg outputs | grep "^Output"
# Output "PNP(BNQ) BenQ BL2581T ET1CL03348SL0" (DP-8)
# Output "PNP(BNQ) BenQ BL2581T ET1CL03342SL0" (DP-9)
# Output "AU Optronics 0xD291 Unknown" (eDP-1)
```

### Stable Identifiers (EDID Description)

Connector names (`DP-6`, `DP-8`) change on every dock disconnect/reconnect. Use the full EDID description string from `niri msg outputs` as the output name — it includes the serial number and is stable across hotplug events.

| Identifier type | Example | Stable across hotplug? |
|----------------|---------|----------------------|
| Connector name | `DP-8` | No — changes every reconnect |
| EDID description | `PNP(BNQ) BenQ BL2581T ET1CL03348SL0` | Yes — tied to physical monitor |
| `eDP-1` | Laptop panel | Yes — always the same |

### Dock Setup (2x BenQ BL2581T + Laptop)

```kdl
// Left: BenQ BL2581T (serial ..48SL0)
output "PNP(BNQ) BenQ BL2581T ET1CL03348SL0" {
    mode "1920x1200@59.950"
    scale 1.0
    transform "normal"
    position x=0 y=0
}

// Center: BenQ BL2581T (serial ..42SL0)
output "PNP(BNQ) BenQ BL2581T ET1CL03342SL0" {
    mode "1920x1200@59.950"
    scale 1.0
    transform "normal"
    position x=1920 y=0
}

// Right: Laptop display
output "eDP-1" {
    mode "1920x1200@60.026"
    scale 1.25
    transform "normal"
    position x=3840 y=0
}
```

### Runtime Commands

```bash
# List monitors
niri msg outputs

# Reload config
niri msg action load-config-file

# Verify positions
niri msg outputs | grep -E "^Output|Logical position"
```

### hyprdynamicmonitors on Niri

hyprdynamicmonitors is Hyprland-specific and will not run under Niri. The systemd service has `ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE`, so it is automatically skipped when Niri is the compositor.

## Quick Reference

### Hyprland

```bash
hyprctl monitors
hyprctl reload
hyprctl dispatch dpms off
hyprctl dispatch dpms on
journalctl --user -u hyprdynamicmonitors
```

### Niri

```bash
niri msg outputs
niri msg action load-config-file
```

## Related

- [14-NIRI.md](./14-NIRI.md) - Niri compositor configuration
- [../hardware/04-DISPLAY-GRAPHICS.md](../hardware/04-DISPLAY-GRAPHICS.md) - Graphics hardware
- [02-CONFIGURATION](./02-CONFIGURATION.md) - Config structure
