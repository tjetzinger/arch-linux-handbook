# Dotfiles

Configuration files for Hyprland/ML4W desktop environment on ThinkPad X1 Carbon Gen 11.

## Structure

```
dotfiles/
├── hypr/                           # Hyprland configs
│   ├── conf/
│   │   ├── custom.conf             # Main customization hub
│   │   ├── autostart-custom.conf   # Custom autostart apps
│   │   ├── ttkeyboard.conf         # Keyboard/touchpad settings
│   │   └── windowrules/
│   │       └── custom.conf         # Window rules
│   ├── hypridle-custom.conf        # Custom idle timeouts
│   └── scripts/
│       └── hypridle-toggle         # Waybar toggle script
├── waybar/
│   └── modules-custom.json         # Module overrides (first wins)
├── hyprdynamicmonitors/
│   ├── config.toml                 # Monitor profile config
│   └── hyprconfigs/
│       ├── DualMonitorDock.go.tmpl # Docked mode (lid-aware)
│       ├── LaptopMode.conf         # Undocked mode
│       └── fallback.conf           # Fallback config
├── systemd/
│   └── user/
│       └── hyprdynamicmonitors.service.d/
│           └── override.conf       # Enable lid events
└── system/                         # System-wide configs (requires sudo)
    ├── logind.conf.d/
    │   └── 10-lid-switch.conf      # Lid switch behavior
    ├── wireplumber.conf.d/
    │   └── 99-disable-bt-hw-volume.conf  # Bluetooth volume fix
    └── tlp.d/
        └── 10-thinkpad.conf        # TLP power management
```

## Installation

### User Configs

```bash
# Hyprland
cp -r hypr/conf/* ~/.config/hypr/conf/
cp hypr/hypridle-custom.conf ~/.config/hypr/
mkdir -p ~/.local/bin
cp hypr/scripts/hypridle-toggle ~/.local/bin/
chmod +x ~/.local/bin/hypridle-toggle

# Waybar
cp waybar/modules-custom.json ~/.config/waybar/

# hyprdynamicmonitors
cp hyprdynamicmonitors/config.toml ~/.config/hyprdynamicmonitors/
cp -r hyprdynamicmonitors/hyprconfigs/* ~/.config/hyprdynamicmonitors/hyprconfigs/

# Systemd user override
mkdir -p ~/.config/systemd/user/hyprdynamicmonitors.service.d
cp systemd/user/hyprdynamicmonitors.service.d/override.conf ~/.config/systemd/user/hyprdynamicmonitors.service.d/
systemctl --user daemon-reload
```

### System Configs (requires sudo)

```bash
# Lid switch behavior
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp system/logind.conf.d/10-lid-switch.conf /etc/systemd/logind.conf.d/
sudo systemctl restart systemd-logind

# Bluetooth volume fix
sudo mkdir -p /etc/wireplumber/wireplumber.conf.d
sudo cp system/wireplumber.conf.d/99-disable-bt-hw-volume.conf /etc/wireplumber/wireplumber.conf.d/
systemctl --user restart wireplumber

# TLP power management
sudo cp system/tlp.d/10-thinkpad.conf /etc/tlp.d/
sudo tlp start
```

## Key Features

### Hyprland (`custom.conf`)
- German keyboard layout (de, nodeadkeys)
- Natural scroll for M590 mouse and TrackPoint
- MX Keys Mini forced to German layout
- 3-finger horizontal swipe for workspace switching
- split-monitor-workspaces plugin (3 per monitor)
- Borderless windows with 5/7 gaps

### Idle Behavior (`hypridle-custom.conf`)
- 8min: Dim screen to 10%
- 11min: DPMS off
- **No auto-lock, no auto-suspend** (commented out)

### Monitor Management (`hyprdynamicmonitors`)
- Auto-detects dock (2x BenQ BL2581T)
- Lid-aware: disables laptop screen when lid closed
- Fallback for unknown monitor configs

### Power Management
- **Logind**: Ignore lid switch on AC power or when docked
- **TLP**: Battery thresholds 75-80%, turbo off on battery, USB denylist for eMeet Luna
- **WirePlumber**: Disable Bluetooth hardware volume (fixes volume control issues)

## Related Documentation

- [desktop/11-CUSTOMIZATION.md](../desktop/11-CUSTOMIZATION.md) - Full customization guide
- [desktop/04-MONITORS.md](../desktop/04-MONITORS.md) - Monitor setup
- [hardware/02-POWER-BATTERY.md](../hardware/02-POWER-BATTERY.md) - TLP configuration
