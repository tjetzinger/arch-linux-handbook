# 02 - Browsers

Web browser configuration - Chrome (primary) and Firefox.

## Google Chrome

Primary web browser.

### Launch

```bash
google-chrome-stable

# Or via application menu
# Super + Space -> Chrome
```

### Configuration

**Directory:** `~/.config/google-chrome/`

```
~/.config/google-chrome/
├── Default/              # Default profile
│   ├── Preferences       # Settings
│   ├── Bookmarks         # Bookmarks JSON
│   ├── History           # Browsing history
│   ├── Login Data        # Saved passwords
│   └── Extensions/       # Installed extensions
├── Local State           # Browser state
└── Safe Browsing/        # Security data
```

### Profile

Default profile at `Default/` contains:
- Preferences and settings
- Bookmarks
- Extensions
- Cookies and login data

### Debug Mode

For automation and testing:

```bash
# Launch with remote debugging
google-chrome-stable --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-profile-stable

# Alias defined
chrome-debug
```

### Set as Default

```bash
xdg-settings set default-web-browser google-chrome.desktop
```

### MIME Types

Chrome handles:
- `text/html`
- `x-scheme-handler/http`
- `x-scheme-handler/https`
- `application/pdf`

## Firefox

Backup browser.

### Launch

```bash
firefox
```

### Configuration

**Directory:** `~/.mozilla/firefox/`

```
~/.mozilla/firefox/
├── profiles.ini          # Profile configuration
├── *.default-release/    # Default profile
│   ├── prefs.js          # User preferences
│   ├── places.sqlite     # Bookmarks/history
│   └── extensions/       # Add-ons
└── installs.ini          # Installation info
```

### Profile Management

```bash
# Open profile manager
firefox -ProfileManager

# Create new profile
firefox -CreateProfile "ProfileName"

# Run with specific profile
firefox -P "ProfileName"
```

### about: Pages

| Page | Description |
|------|-------------|
| `about:config` | Advanced settings |
| `about:preferences` | Settings GUI |
| `about:addons` | Extension management |
| `about:profiles` | Profile management |
| `about:support` | Troubleshooting info |

## Profile Sync Daemon (RAM Profiles)

Both Chrome and Firefox profiles run from RAM using profile-sync-daemon (psd) for improved performance and reduced SSD wear.

### How It Works

| Component | Description |
|-----------|-------------|
| Base profile | Stored on disk (read-only via overlayfs) |
| Changes | Stored in tmpfs (RAM) |
| Sync | Periodic + on suspend + on shutdown |
| Recovery | Automatic crash recovery backups |

### Configuration

**File:** `~/.config/psd/psd.conf`

```bash
USE_OVERLAYFS="yes"
USE_SUSPSYNC="yes"
BROWSERS=(google-chrome firefox)
```

### Profile Locations

| Browser | Disk Location | RAM Location |
|---------|---------------|--------------|
| Chrome | `~/.config/google-chrome` | `/run/user/1000/psd/tt-google-chrome` |
| Firefox | `~/.mozilla/firefox/*` | `/run/user/1000/psd/tt-firefox-*` |

**Note:** The disk locations are symlinks to the RAM locations when psd is active.

### Management

```bash
# Check status
psd p

# Service control
systemctl --user status psd.service
systemctl --user restart psd.service

# Force sync to disk
psd resync
```

### Status Output

```
systemd service:    active
resync-timer:       active
sync on sleep:      enabled
use overlayfs:      enabled

browser/psname:     google-chrome/chrome
profile size:       6.5G
overlayfs size:     250M    # Only changes stored in RAM
```

### Important Notes

- **Close browsers before stopping psd** to ensure data is synced
- Overlayfs means only changes use RAM, not the full profile
- Crash recovery keeps last 5 snapshots in `~/.config/google-chrome-backup-*`
- Syncs automatically on suspend/hibernate (protects laptop usage)

---

## Browser Settings

### Privacy

Both browsers support:
- Do Not Track
- Enhanced Tracking Protection
- Cookie controls
- Site permissions

### Wayland Support

Both browsers run natively on Wayland. Environment variables set in Hyprland:

```bash
# In ~/.config/hypr/conf/custom.conf
env = MOZ_ENABLE_WAYLAND,1
```

### Hardware Acceleration

Chrome uses VA-API for video acceleration (configured system-wide via Intel drivers).

## Cookie Integration

### yt-dlp Integration

Both browsers can share cookies with yt-dlp:

```bash
# Use Chrome cookies
yt-dlp --cookies-from-browser chrome <url>

# Use Firefox cookies
yt-dlp --cookies-from-browser firefox <url>
```

Alias configured:
```bash
alias yt-dlp='yt-dlp --cookies-from-browser chrome'
```

### mpv Integration

mpv also uses Chrome cookies for YouTube:

```bash
# In ~/.config/mpv/mpv.conf
ytdl-raw-options=cookies-from-browser=chrome
```

## Syncing

### Chrome Sync

Sign in with Google account for:
- Bookmarks
- Extensions
- Settings
- Passwords
- History

### Firefox Sync

Sign in with Firefox account for similar sync features.

## Extensions

### Recommended Extensions

| Extension | Purpose |
|-----------|---------|
| uBlock Origin | Ad blocking |
| Bitwarden | Password management |
| Dark Reader | Dark mode for sites |

### Extension Management

Chrome:
```
chrome://extensions/
```

Firefox:
```
about:addons
```

## Troubleshooting

### Chrome Won't Start

```bash
# Check for crashes
ls ~/.config/google-chrome/Crash\ Reports/

# Start with clean profile
google-chrome-stable --user-data-dir=/tmp/chrome-test

# Reset to defaults (backup first!)
mv ~/.config/google-chrome ~/.config/google-chrome.bak
```

### Firefox Issues

```bash
# Safe mode
firefox --safe-mode

# Refresh Firefox (keeps bookmarks, removes extensions)
# about:support -> Refresh Firefox
```

### GPU Issues

```bash
# Check GPU status
# Chrome: chrome://gpu/
# Firefox: about:support (Graphics section)

# Disable GPU acceleration
google-chrome-stable --disable-gpu
```

### Profile-Sync-Daemon Issues

```bash
# Browser won't start (psd not running)
systemctl --user start psd.service

# Profile corrupted after crash
# psd keeps backups - restore from:
ls ~/.config/google-chrome-backup-crashrecovery-*
cp -a ~/.config/google-chrome-backup-crashrecovery-TIMESTAMP/* ~/.config/google-chrome/

# Force resync before shutdown
psd resync

# Disable psd temporarily (close browsers first!)
systemctl --user stop psd.service
# Profile reverts to disk location
```

## Quick Reference

```bash
# Launch browsers
google-chrome-stable
firefox

# Debug mode
chrome-debug

# Set default browser
xdg-settings set default-web-browser google-chrome.desktop

# Check default
xdg-settings get default-web-browser

# Config locations
~/.config/google-chrome/
~/.mozilla/firefox/

# Profile-sync-daemon
psd p                              # Status and RAM usage
psd resync                         # Force sync to disk
systemctl --user status psd        # Service status
```

## Related

- [06-MEDIA](./06-MEDIA.md) - yt-dlp and mpv browser integration
- [01-OVERVIEW](./01-OVERVIEW.md) - Default applications
