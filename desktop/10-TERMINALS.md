# 10 - Terminals

Terminal emulators: **Alacritty** is the daily terminal. Warp and Kitty are installed as extras.

> Until 2026-02-20 the ML4W setup used Warp as default (set in `~/.config/ml4w/settings/terminal.sh`) with Kitty as backup. Under Niri, Mod+Return opens Alacritty.

## Alacritty (Default)

| Setting | Value |
|---------|-------|
| Launch | Mod+Return (`~/.config/niri/binds.kdl`) |
| Config | `~/.config/niri-setup/alacritty/default.toml` (passed with `--config-file`) |
| Font | JetBrainsMono Nerd Font, Regular, size 12 |
| Window | opacity 0.93, padding 15 px |
| Colors | Solarized Dark (`#002b36` background, `#839496` foreground) |

```kdl
Mod+Return      { spawn-sh "alacritty --config-file $NIRICONF/alacritty/default.toml"; }
```

```toml
[font]
size = 12

[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"

[window]
opacity = 0.93

[window.padding]
x = 15
y = 15
```

The config lives in the niri-setup repo, not in `~/.config/alacritty/`; edit it there and commit (see [applications/12-DOTFILES](../applications/12-DOTFILES.md)). Alacritty reloads its config file automatically when it changes.

### Floating Helper Windows

`float.toml` is the same config with opacity 0.9. Niri opens these Alacritty windows floating (`~/.config/niri/rules.kdl`, matched by title):

| Title | Started by |
|-------|------------|
| `Updater` | Mod+U (system update) |
| `Wallpaper Selector` | Mod+Ctrl+W |
| `nmtui` | Waybar network module |

```kdl
// excerpt; the same rule also floats Calculator and pwvucontrol
window-rule {
    match app-id="Alacritty" title="Updater"
    match app-id="Alacritty" title="nmtui"
    match app-id="Alacritty" title="Wallpaper Selector"
    open-floating true
}
```

## Warp (Installed)

`warp-terminal-bin`, launched with `warp-terminal`. Config: `~/.config/warp-terminal/user_preferences.json`. Not bound to a key under Niri.

## Kitty (Installed)

Launched with `kitty`. Config: `~/.config/kitty/kitty.conf`. The ML4W-era config there may still include pywal/matugen color files that no longer update.

## Changing the Default Terminal

Edit the Mod+Return line in `~/.config/niri/binds.kdl`, for example:

```kdl
Mod+Return      { spawn "warp-terminal"; }
```

Niri reloads the file on save; check it with `niri validate`. The Mod+U and Mod+Ctrl+W helpers keep using Alacritty unless their lines are changed too.

## Troubleshooting

### Terminal Won't Launch

```bash
# Start from another terminal to see errors
alacritty --config-file ~/.config/niri-setup/alacritty/default.toml

# Niri spawn errors
journalctl --user -u niri -b | grep -i alacritty
```

### Font Missing

The font is installed by hand in `~/.local/share/fonts/JetBrainsMonoNerd/` (no package owns it), so a fresh install needs it copied back or the package instead:

```bash
fc-list | grep -i "JetBrainsMono Nerd"
sudo pacman -S ttf-jetbrains-mono-nerd   # packaged alternative
fc-cache -f
```

### Transparency Not Working

Check `opacity` in the `[window]` section; Niri itself needs no setting for transparent windows.

## Quick Reference

```bash
alacritty                               # default terminal (Mod+Return)
alacritty --config-file ~/.config/niri-setup/alacritty/float.toml   # floating variant
warp-terminal                           # Warp
kitty                                   # Kitty
```

## Related

- [09-THEMING](./09-THEMING.md) - Colors and fonts
- [14-NIRI](./14-NIRI.md) - Keybindings
