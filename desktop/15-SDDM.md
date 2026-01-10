# SDDM Display Manager

Configuration and fixes for SDDM (Simple Desktop Display Manager) with the Sequoia theme.

## Overview

SDDM is the display manager used to handle login sessions. It runs before the compositor starts and allows selecting between different desktop sessions (Hyprland, Niri, etc.).

## Configuration

| File | Purpose |
|------|---------|
| `/etc/sddm.conf.d/sddm.conf` | Main SDDM configuration |
| `/usr/share/sddm/themes/` | Installed themes |
| `/usr/share/sddm/themes/sequoia/theme.conf` | Sequoia theme settings |

### Current Configuration

```ini
[Theme]
Current=sequoia
```

## Sequoia Theme

Sequoia is a modern theme using Nerd Font icons.

### Dependencies

| Package | Purpose |
|---------|---------|
| `sddm` | Display manager |
| `qt6-declarative` | Qt6 QML support |
| `qt6-5compat` | Qt5 compatibility layer |
| Nerd Font (system-wide) | Icon rendering |

### Required Fixes

The packaged sequoia theme has two bugs that prevent dropdown menus from working:

#### Fix 1: Icon Font Configuration

The theme ships with wrong icon font setting.

**File:** `/usr/share/sddm/themes/sequoia/theme.conf`

```bash
# Fix: Change Font Awesome to a Nerd Font
sudo sed -i 's/iconFont="Font Awesome 6 Free"/iconFont="FiraCode Nerd Font"/' \
  /usr/share/sddm/themes/sequoia/theme.conf
```

| Before | After |
|--------|-------|
| `iconFont="Font Awesome 6 Free"` | `iconFont="FiraCode Nerd Font"` |

The theme uses Nerd Font icon codepoints, not Font Awesome.

#### Fix 2: PopupPanel Delegate Bug

The PopupPanel component explicitly sets an undefined delegate, breaking all dropdown menus.

**File:** `/usr/share/sddm/themes/sequoia/components/common/PopupPanel.qml`

```bash
# Fix: Remove the explicit delegate assignment (line 43)
sudo sed -i 's/delegate: menu.delegate//' \
  /usr/share/sddm/themes/sequoia/components/common/PopupPanel.qml
```

| Before | After |
|--------|-------|
| `delegate: menu.delegate` | (removed) |

When using ComboBox's `delegateModel`, the Repeater should not have an explicit delegate - the DelegateModel already contains delegate information.

### Apply All Fixes

```bash
# Fix icon font
sudo sed -i 's/iconFont="Font Awesome 6 Free"/iconFont="FiraCode Nerd Font"/' \
  /usr/share/sddm/themes/sequoia/theme.conf

# Fix popup delegate
sudo sed -i 's/delegate: menu.delegate//' \
  /usr/share/sddm/themes/sequoia/components/common/PopupPanel.qml
```

### Verify Fixes

```bash
# Check icon font setting
grep iconFont /usr/share/sddm/themes/sequoia/theme.conf

# Check PopupPanel (should NOT contain 'delegate: menu.delegate')
grep -n "delegate:" /usr/share/sddm/themes/sequoia/components/common/PopupPanel.qml
```

## Testing

Test themes without logging out:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sequoia
```

## Troubleshooting

### Dropdowns Not Working

**Symptoms:**
- Clicking session/user/language selector shows nothing
- Icons visible but no dropdown appears
- Greeter may crash

**Solution:** Apply both fixes above.

### Icons Not Rendering

**Symptoms:**
- Boxes or blank spaces instead of icons

**Solution:**
1. Verify a Nerd Font is installed system-wide:
   ```bash
   fc-list | grep -i "nerd"
   ```
2. Update `theme.conf` to use installed Nerd Font name

### Check Logs

```bash
# SDDM service logs
journalctl -u sddm -b

# Check for crashes
journalctl -u sddm | grep -i "crash\|error"
```

## Available Sessions

Sessions available for selection:

| Session | File |
|---------|------|
| Hyprland | `/usr/share/wayland-sessions/hyprland.desktop` |
| Hyprland (uwsm) | `/usr/share/wayland-sessions/hyprland-uwsm.desktop` |
| Niri | `/usr/share/wayland-sessions/niri.desktop` |

## Package Update Warning

These fixes modify system files that may be overwritten by package updates. After updating `sddm` or the sequoia theme package, reapply the fixes.

Consider creating a pacman hook to preserve fixes:

```bash
# /etc/pacman.d/hooks/sddm-sequoia-fix.hook
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = sddm-theme-sequoia

[Action]
Description = Fixing SDDM Sequoia theme...
When = PostTransaction
Exec = /usr/local/bin/fix-sddm-sequoia.sh
```

## Related

- [14-NIRI](./14-NIRI.md) - Niri compositor (alternative session)
- [01-OVERVIEW](./01-OVERVIEW.md) - Hyprland overview
