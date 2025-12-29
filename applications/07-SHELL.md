# 07 - Shell

Zsh configuration with oh-my-zsh and oh-my-posh.

## Overview

| Component | Choice |
|-----------|--------|
| Shell | Zsh |
| Framework | oh-my-zsh |
| Prompt | oh-my-posh |
| Theme | EDM115-newline |

## Configuration

### Modular Structure

**Directory:** `~/.config/zshrc/` (symlinked from dotfiles)

```
~/.config/zshrc/
├── 00-init           # Initialization, exports
├── 01-tmux           # Tmux auto-start
├── 20-customization  # oh-my-zsh, oh-my-posh
├── 25-aliases        # Command aliases
├── 30-autostart      # Autostart scripts
└── custom/           # Custom overrides (not tracked)
```

### Main Loader

**File:** `~/.zshrc`

Loads modular config files in order.

## 00-init

Initialization and exports:

```bash
export EDITOR=nvim
export PATH="/usr/lib/ccache/bin/:$PATH"
export ZSH="$HOME/.oh-my-zsh"
```

## 01-tmux

Auto-starts tmux with grouped sessions. See [14-TMUX](./14-TMUX.md) for details.

## 20-customization

### oh-my-zsh Plugins

```bash
plugins=(
    git
    sudo
    web-search
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
    fast-syntax-highlighting
    copyfile
    copybuffer
    dirhistory
)
```

### Plugin Descriptions

| Plugin | Description |
|--------|-------------|
| git | Git aliases and functions |
| sudo | Double ESC to add sudo |
| web-search | Search web from terminal |
| archlinux | Pacman/yay aliases |
| zsh-autosuggestions | Fish-like suggestions |
| zsh-syntax-highlighting | Syntax colors |
| fast-syntax-highlighting | Faster highlighting |
| copyfile | Copy file contents |
| copybuffer | Copy command line |
| dirhistory | Alt+arrows for dir history |

### FZF Integration

```bash
source <(fzf --zsh)
```

Enables:
- `Ctrl+R` - Fuzzy history search
- `Ctrl+T` - Fuzzy file finder
- `Alt+C` - Fuzzy cd

### History Settings

```bash
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
```

### oh-my-posh

Disabled in Warp Terminal (has its own prompt):

```bash
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]]; then
    eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/EDM115-newline.omp.json)"
fi
```

### SSH Agent

Auto-loads SSH key on shell start:

```bash
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
if ! ssh-add -l &>/dev/null; then
    ssh-add ~/.ssh/id_ed25519
fi
```

### PATH Extensions

```bash
export PATH="$HOME/scripts:$PATH"
export PATH="$HOME/.local/bin:$PATH"
```

### NVM

Node Version Manager initialization:

```bash
source /usr/share/nvm/init-nvm.sh
```

## 25-aliases

### General Aliases

```bash
alias sudo='sudo '              # Expand aliases after sudo
alias c='clear'
alias nf='fastfetch'
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
alias shutdown='systemctl poweroff'
alias v='nvim'
alias vim='nvim'
alias sv='sudo -E nvim'         # sudo nvim with user's LazyVim config
alias wifi='nmtui'
```

### ML4W Aliases

```bash
alias ml4w='flatpak run com.ml4w.welcome'
alias ml4w-settings='flatpak run com.ml4w.settings'
alias ml4w-diagnosis='~/.config/hypr/scripts/diagnosis.sh'
alias ml4w-update='~/.config/ml4w/update.sh'
```

### System Aliases

```bash
alias ts='~/.config/ml4w/scripts/snapshot.sh'
alias cleanup='~/.config/ml4w/scripts/cleanup.sh'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
```

### Tool Aliases

```bash
alias yt-dlp='yt-dlp --cookies-from-browser chrome'
alias chrome-debug='/usr/bin/google-chrome-stable --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-profile-stable'
alias ollama='docker exec ollama ollama'
```

### Flatpak Applications

```bash
alias firefox='flatpak run org.mozilla.firefox'
```

## 30-autostart

Runs fastfetch on terminal start:

```bash
if [[ $(tty) == *"pts"* ]]; then
    fastfetch --config examples/13
fi
```

## oh-my-posh Theme

**File:** `~/.config/ohmyposh/EDM115-newline.omp.json`

Features:
- Git status
- Directory path
- Command duration
- Exit code indicator
- Newline prompt

Alternative theme available: `zen.toml`

## Useful Commands

### Git (via plugin)

```bash
gst     # git status
ga      # git add
gc      # git commit
gp      # git push
gpl     # git pull
gco     # git checkout
gb      # git branch
```

### Archlinux (via plugin)

```bash
pacin   # pacman -S
pacss   # pacman -Ss
pacrem  # pacman -Rns
yain    # yay -S
yaupg   # yay -Syu
```

### Web Search (via plugin)

```bash
google "search term"
ddg "search term"
github "search term"
```

## Customization

### Add Custom Aliases

Edit `~/.config/zshrc/25-aliases`:

```bash
# Add at end of file
alias myalias='command'
```

Then reload:

```bash
source ~/.zshrc
```

### Change oh-my-posh Theme

Edit `~/.config/zshrc/20-customization`:

```bash
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
```

## Troubleshooting

### Shell Slow to Start

```bash
# Profile startup time
zsh -xv 2>&1 | head -100

# Common culprits:
# - NVM (slow on every shell)
# - Many oh-my-zsh plugins
```

### Autosuggestions Not Working

```bash
# Check plugin is installed
ls ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Install if missing
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
```

### FZF Not Working

```bash
# Check fzf installed
which fzf

# Install if missing
sudo pacman -S fzf
```

## Quick Reference

```bash
# Reload config
source ~/.zshrc

# Edit config
$EDITOR ~/.config/zshrc/25-aliases

# Check shell
echo $SHELL

# List aliases
alias

# History
history
fc -l -20   # Last 20 commands

# Config location
~/.config/zshrc/
~/.oh-my-zsh/
~/.config/ohmyposh/
```

## Related

- [08-GIT-SSH](./08-GIT-SSH.md) - Git configuration
- [12-DOTFILES](./12-DOTFILES.md) - Dotfiles management
- [14-TMUX](./14-TMUX.md) - Tmux multiplexer
