# 06 - Media

Media players and tools - VLC, mpv, GIMP, yt-dlp.

## mpv

Lightweight, scriptable media player.

### Launch

```bash
mpv video.mp4
mpv audio.mp3
mpv https://youtube.com/watch?v=...
```

### Configuration

**File:** `~/.config/mpv/mpv.conf`

```ini
hwdec=vaapi
vo=gpu
gpu-context=wayland
ytdl-raw-options=cookies-from-browser=chrome
```

### Key Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| hwdec | vaapi | Hardware video decoding |
| vo | gpu | GPU video output |
| gpu-context | wayland | Wayland native |
| ytdl-raw-options | cookies-from-browser=chrome | YouTube auth |

### Keyboard Controls

| Key | Action |
|-----|--------|
| `Space` | Pause/play |
| `←/→` | Seek 5s |
| `↑/↓` | Seek 60s |
| `[/]` | Speed decrease/increase |
| `m` | Mute |
| `f` | Fullscreen |
| `q` | Quit |
| `s` | Screenshot |
| `9/0` | Volume down/up |

### YouTube Playback

mpv can play YouTube directly via yt-dlp:

```bash
mpv "https://youtube.com/watch?v=VIDEO_ID"
```

Cookies from Chrome are used for authentication.

## VLC

Full-featured media player.

### Launch

```bash
vlc video.mp4
vlc audio.mp3
```

### Configuration

**Directory:** `~/.config/vlc/`

```
~/.config/vlc/
├── vlcrc              # Main configuration
└── vlc-qt-interface.conf  # Qt interface settings
```

### Key Controls

| Key | Action |
|-----|--------|
| `Space` | Pause/play |
| `f` | Fullscreen |
| `Ctrl+H` | Hide controls |
| `+/-` | Speed up/down |
| `[/]` | Slower/faster |
| `m` | Mute |
| `Ctrl+Q` | Quit |

### Preferences

Access via Tools > Preferences or `Ctrl+P`.

## yt-dlp

YouTube and video site downloader.

### Basic Usage

```bash
# Download video
yt-dlp "https://youtube.com/watch?v=..."

# Download audio only
yt-dlp -x "https://youtube.com/watch?v=..."

# Best quality
yt-dlp -f best "https://youtube.com/watch?v=..."

# List formats
yt-dlp -F "https://youtube.com/watch?v=..."
```

### Configuration

**Directory:** `~/.config/yt-dlp/`

### Alias

Configured alias uses Chrome cookies:

```bash
alias yt-dlp='yt-dlp --cookies-from-browser chrome'
```

### Common Options

| Option | Description |
|--------|-------------|
| `-x` | Extract audio |
| `-f best` | Best quality |
| `-F` | List formats |
| `--audio-format mp3` | Convert to MP3 |
| `-o "%(title)s.%(ext)s"` | Output template |
| `--playlist-items 1-5` | Download range |

### Download Playlist

```bash
# Entire playlist
yt-dlp "https://youtube.com/playlist?list=..."

# First 5 videos
yt-dlp --playlist-items 1-5 "https://youtube.com/playlist?list=..."
```

## GIMP

Image editing application.

### Launch

```bash
gimp
gimp image.png
```

### Configuration

**Directory:** `~/.config/GIMP/3.0/`

### Key Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+O` | Open |
| `Ctrl+S` | Save |
| `Ctrl+Shift+E` | Export |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |
| `+/-` | Zoom in/out |
| `1` | Zoom 100% |

### Tools

| Key | Tool |
|-----|------|
| `P` | Pencil |
| `B` | Paintbrush |
| `E` | Eraser |
| `R` | Rectangle select |
| `O` | Ellipse select |
| `F` | Free select |
| `T` | Text |
| `M` | Move |

## Hardware Acceleration

### VA-API (Intel)

Video acceleration configured for Intel Iris Xe:

```bash
# Check VA-API status
vainfo

# mpv uses vaapi
hwdec=vaapi
```

### Verify Acceleration

```bash
# Play video and check
mpv --hwdec=vaapi video.mp4

# Check decoder in use (press I during playback)
```

## Audio

Both mpv and VLC use PipeWire for audio output.

### Volume Control

```bash
# System volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%

# Mute
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

## Screenshot Tools

### mpv Screenshots

```bash
# In mpv, press 's' for screenshot
# Saved to ~/mpv-shot*.png
```

### VLC Screenshots

Video > Take Snapshot or `Shift+S`

## Quick Reference

```bash
# Media players
mpv <file>            # Lightweight player
vlc <file>            # Full-featured player

# YouTube
yt-dlp <url>          # Download video
yt-dlp -x <url>       # Download audio
mpv <youtube-url>     # Stream directly

# Image editing
gimp <image>          # Edit image

# Config locations
~/.config/mpv/mpv.conf
~/.config/vlc/vlcrc
~/.config/yt-dlp/
~/.config/GIMP/
```

## Related

- [02-BROWSERS](./02-BROWSERS.md) - Browser cookie integration
- [../hardware/05-AUDIO](../hardware/05-AUDIO.md) - Audio configuration
