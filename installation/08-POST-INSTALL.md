# 08 - Post-Installation

Final configuration, essential packages, and system hardening.

---

## Step 1: Create Snapshot of Working System

Before making more changes:

```bash
sudo snapper -c root create -d "Post-install baseline - working system"
```

---

## Step 2: Essential Package Groups

### Complete Package Installation

```bash
# System utilities
sudo pacman -S \
    acpi acpid tlp powertop \
    smartmontools nvme-cli \
    htop btop \
    tree ncdu duf \
    rsync rclone \
    unzip p7zip unrar \
    wget curl \
    man-db man-pages

# Development
sudo pacman -S \
    base-devel git \
    neovim vim \
    tmux \
    fzf ripgrep fd bat eza \
    jq yq \
    python python-pip \
    nodejs npm \
    docker docker-compose

# Networking
sudo pacman -S \
    networkmanager \
    openssh \
    ufw \
    bind-tools \
    traceroute \
    nmap \
    tailscale

# Multimedia
sudo pacman -S \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    mpv ffmpeg \
    imagemagick

# Fonts
sudo pacman -S \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd \
    ttf-font-awesome \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    ttf-liberation
```

### AUR Packages

```bash
yay -S \
    google-chrome \
    visual-studio-code-bin \
    spotify \
    discord \
    1password \
    bibata-cursor-theme-bin
```

---

## Step 3: Enable Services

```bash
# Power management
sudo systemctl enable acpid tlp

# Docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Tailscale (VPN)
sudo systemctl enable tailscaled

# SSD maintenance
sudo systemctl enable fstrim.timer

# Snapper
sudo systemctl enable snapper-timeline.timer snapper-cleanup.timer

# Reflector (mirror updates)
sudo systemctl enable reflector.timer
```

---

## Step 4: Backup Configuration

### Setup Borg Repository

```bash
# Initialize local repo (external drive)
sudo borg init --encryption=repokey /mnt/external/borg-backup

# Export key
sudo borg key export /mnt/external/borg-backup ~/Documents/borg-key.txt
```

### Create Backup Script

See [../system-recovery/07-BORG-BACKUP-AUTOMATION.md](../system-recovery/07-BORG-BACKUP-AUTOMATION.md)

### Backup LUKS Header

```bash
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 \
    --header-backup-file ~/Documents/luks-header-$(date +%Y%m%d).bin
```

---

## Step 5: Dotfiles Management

### Using Git Bare Repository

```bash
# Initialize
git init --bare $HOME/.dotfiles

# Alias
echo "alias dotfiles='git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME'" >> ~/.zshrc
source ~/.zshrc

# Configure
dotfiles config --local status.showUntrackedFiles no

# Add files
dotfiles add ~/.zshrc
dotfiles add ~/.config/hypr/
dotfiles commit -m "Initial dotfiles"
dotfiles push
```

### Or Use GNU Stow

```bash
sudo pacman -S stow

# Create dotfiles directory
mkdir -p ~/dotfiles
cd ~/dotfiles

# Create package structure
mkdir -p zsh/.config
mkdir -p hypr/.config/hypr
# Move configs...

# Deploy
stow zsh hypr
```

---

## Step 6: Shell Configuration

### Zsh with Oh-My-Zsh

```bash
# Install zsh
sudo pacman -S zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions

# Change shell
chsh -s /bin/zsh

# Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### ~/.zshrc Essentials

```bash
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)

# Aliases
alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat'
alias vim='nvim'
alias ..='cd ..'
alias ...='cd ../..'

# Paths
export PATH="$HOME/.local/bin:$PATH"
```

---

## Step 7: Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.editor nvim

# GitHub CLI
gh auth login
```

---

## Step 8: Security Hardening

### Firewall Rules

```bash
# Basic rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# Allow specific services (as needed)
sudo ufw allow ssh
sudo ufw allow 1714:1764/udp  # KDE Connect
sudo ufw allow 1714:1764/tcp  # KDE Connect
```

### Kernel Hardening

```bash
sudo tee /etc/sysctl.d/99-security.conf << 'EOF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.sysrq = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF

sudo sysctl --system
```

### Restrict Boot Editor

Already done in loader.conf (`editor no`).

---

## Step 9: Maintenance Automation

### Create Maintenance Script

```bash
sudo tee /usr/local/bin/system-maintenance << 'EOF'
#!/bin/bash
set -e

echo "=== System Maintenance $(date) ==="

echo "1. Updating mirrors..."
sudo reflector --country Germany,Austria,Switzerland --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist

echo "2. Updating system..."
sudo pacman -Syu --noconfirm

echo "3. Updating AUR packages..."
yay -Sua --noconfirm

echo "4. Cleaning package cache..."
sudo pacman -Sc --noconfirm
yay -Sc --noconfirm

echo "5. Cleaning orphaned packages..."
orphans=$(pacman -Qdtq)
if [[ -n "$orphans" ]]; then
    sudo pacman -Rns $orphans --noconfirm
fi

echo "6. Snapper cleanup..."
sudo snapper cleanup timeline
sudo snapper cleanup number

echo "7. Btrfs maintenance..."
sudo btrfs scrub start -B /

echo "=== Maintenance complete ==="
EOF

sudo chmod +x /usr/local/bin/system-maintenance
```

### Monthly Timer

```bash
# Service
sudo tee /etc/systemd/system/system-maintenance.service << 'EOF'
[Unit]
Description=Monthly System Maintenance

[Service]
Type=oneshot
ExecStart=/usr/local/bin/system-maintenance
EOF

# Timer
sudo tee /etc/systemd/system/system-maintenance.timer << 'EOF'
[Unit]
Description=Monthly System Maintenance Timer

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl enable system-maintenance.timer
```

---

## Step 10: Final Verification

```bash
# Check failed services
systemctl --failed

# Check timers
systemctl list-timers --all

# Check disk health
sudo smartctl -a /dev/nvme0n1

# Check btrfs status
sudo btrfs device stats /

# Check snapper
snapper list

# Create final baseline snapshot
sudo snapper -c root create -d "Post-install complete - baseline"
```

---

## System Summary

After completing all steps, your system should have:

| Component | Status |
|-----------|--------|
| LUKS2 encryption | Enabled with keyfile |
| Btrfs snapshots | Automated with Snapper |
| Boot entries | Main + LTS + Recovery |
| Power management | TLP enabled |
| Firewall | UFW enabled |
| Desktop | Hyprland with ML4W |
| Backup | Borg + rclone ready |
| Maintenance | Monthly automation |

---

## Quick Reference

```bash
# Update system
sudo pacman -Syu
yay -Sua

# Maintenance
system-maintenance

# Snapshots
snapper list
sudo snapper create -d "description"
sudo snapper undochange <pre>..<post>

# Services
systemctl --failed
systemctl list-timers

# Disk health
sudo btrfs device stats /
sudo smartctl -a /dev/nvme0n1
```

---

## Related Documentation

- [System Recovery](../system-recovery/) - Recovery procedures
- [Snapper Usage](../system-recovery/03-SNAPPER-DAILY-USAGE.md) - Detailed snapper guide
- [Backup Strategy](../system-recovery/04-BACKUP-STRATEGY-OVERVIEW.md) - Backup configuration
