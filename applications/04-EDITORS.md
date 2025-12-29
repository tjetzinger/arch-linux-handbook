# 04 - Editors

VS Code configuration.

## VS Code

### Launch

```bash
code

# Open specific directory
code /path/to/project

# Open file
code file.txt
```

### Configuration

**Directory:** `~/.config/Code/User/`

```
~/.config/Code/User/
├── settings.json         # User settings
├── keybindings.json      # Custom keybindings
├── snippets/             # Code snippets
├── globalStorage/        # Extension data
└── workspaceStorage/     # Workspace settings
```

### Key Settings

Notable settings in `settings.json`:

| Setting | Value |
|---------|-------|
| Theme | Atom One Dark |
| Icon Theme | Material Icon |
| Formatter | Ruff (Python) |
| Auto Save | afterDelay |
| Git Autofetch | true |

### Extensions

Installed extensions include:
- Claude Code (Anthropic)
- Python/Pylance
- Ruff (formatter/linter)
- GitLens
- Material Icon Theme

### Claude Code Integration

Claude Code panel configured:

```json
{
  "claude-dev.alwaysShowPanelOption": true
}
```

### Keybindings

Custom keybindings in `keybindings.json`:

```json
[
  {
    "key": "ctrl+shift+c",
    "command": "workbench.action.terminal.toggleTerminal"
  }
]
```

### Settings Sync

VS Code settings sync via Microsoft or GitHub account.

### Workspace Settings

Per-project settings in `.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "./venv/bin/python",
  "editor.formatOnSave": true
}
```

## Common Tasks

### Open in Editor

```bash
# Open current directory
code .

# Open specific file
code ~/.config/hypr/hyprland.conf
```

### Install Extension

```bash
# VS Code
code --install-extension <extension-id>

# List installed
code --list-extensions
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+P` | Quick file open |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+\`` | Toggle terminal |
| `Ctrl+B` | Toggle sidebar |
| `Ctrl+Shift+E` | Explorer |
| `Ctrl+Shift+G` | Source control |

### Multi-Cursor

| Shortcut | Action |
|----------|--------|
| `Alt+Click` | Add cursor |
| `Ctrl+Alt+Up/Down` | Add cursor above/below |
| `Ctrl+D` | Select next occurrence |
| `Ctrl+Shift+L` | Select all occurrences |

## Integration

### Terminal

Integrated terminal uses system default shell (zsh).

### Git

Built-in Git support:
- Source control panel
- Inline blame
- Diff viewer
- Commit interface

### Debugging

Debug configurations in `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}"
    }
  ]
}
```

## Troubleshooting

### VS Code Won't Start

```bash
# Check logs
code --verbose

# Reset settings
mv ~/.config/Code ~/.config/Code.bak
```

### Extension Issues

```bash
# Start without extensions
code --disable-extensions

# Uninstall extension
code --uninstall-extension <extension-id>
```

### Performance

```bash
# Check process usage
code --status

# Disable telemetry
# settings.json: "telemetry.telemetryLevel": "off"
```

## Quick Reference

```bash
# Launch
code

# Open project
code /path/to/project

# Extensions
code --list-extensions
code --install-extension <id>

# Config location
~/.config/Code/User/settings.json
```

## Related

- [03-NEOVIM](./03-NEOVIM.md) - Terminal-based editor
- [07-SHELL](./07-SHELL.md) - Shell integration
