#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 4: Desktop Environment
# ============================================================
# Run this after first boot, as regular user with sudo
# ============================================================

set -e

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this script as root. Run as regular user with sudo access."
    exit 1
fi

echo "=============================================="
echo "Arch Linux Installation - Desktop Setup"
echo "=============================================="

# === Update system ===
echo "Updating system..."
sudo pacman -Syu --noconfirm

# === Install AUR helper ===
echo "Installing yay..."
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin

# === Essential packages ===
echo "Installing essential packages..."
sudo pacman -S --noconfirm --needed \
    acpi acpid tlp \
    alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    bluez bluez-utils \
    polkit-gnome \
    xdg-user-dirs xdg-utils

# === Enable services ===
echo "Enabling services..."
sudo systemctl enable acpid
sudo systemctl enable tlp
sudo systemctl enable bluetooth

# Start user services
systemctl --user enable pipewire pipewire-pulse wireplumber

# Create user directories
xdg-user-dirs-update

# === Snapper ===
echo "Setting up Snapper..."
sudo pacman -S --noconfirm snapper snap-pac

# Fix snapper subvolume
sudo umount /.snapshots 2>/dev/null || true
sudo rmdir /.snapshots 2>/dev/null || true
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
sudo chown :wheel /.snapshots

# Enable snapper timers
sudo systemctl enable snapper-timeline.timer
sudo systemctl enable snapper-cleanup.timer
sudo systemctl start snapper-timeline.timer
sudo systemctl start snapper-cleanup.timer

# === Firewall ===
echo "Setting up firewall..."
sudo pacman -S --noconfirm ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo systemctl enable ufw

# === Hyprland and ML4W ===
echo "Installing Hyprland..."
sudo pacman -S --noconfirm \
    hyprland \
    xorg-xwayland \
    qt5-wayland qt6-wayland \
    wl-clipboard cliphist

echo "Installing ML4W Hyprland..."
yay -S --noconfirm ml4w-hyprland

# === Terminal and essentials ===
echo "Installing desktop applications..."
sudo pacman -S --noconfirm --needed \
    alacritty \
    thunar thunar-archive-plugin thunar-volman gvfs tumbler ffmpegthumbnailer \
    firefox \
    wofi \
    grim slurp swappy \
    mako \
    swaylock \
    brightnessctl playerctl pamixer pavucontrol \
    nm-connection-editor blueman \
    gnome-keyring

# === Fonts ===
echo "Installing fonts..."
sudo pacman -S --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    noto-fonts noto-fonts-cjk noto-fonts-emoji

# === Theming ===
echo "Installing themes..."
sudo pacman -S --noconfirm gnome-themes-extra adwaita-icon-theme nwg-look
yay -S --noconfirm bibata-cursor-theme-bin

# === Zsh ===
echo "Setting up Zsh..."
sudo pacman -S --noconfirm zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions
chsh -s /bin/zsh

# === Development tools ===
echo "Installing development tools..."
sudo pacman -S --noconfirm --needed \
    neovim \
    tmux \
    fzf ripgrep fd bat eza \
    lazygit \
    docker docker-compose

sudo systemctl enable docker
sudo usermod -aG docker "$USER"

# === Auto-start Hyprland ===
echo "Configuring auto-start..."
mkdir -p ~/.config

cat >> ~/.zprofile << 'EOF'

# Start Hyprland on TTY1
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi
EOF

# === Create initial snapshot ===
echo "Creating initial snapshot..."
sudo snapper -c root create -d "Post-install complete"

echo ""
echo "=============================================="
echo "Desktop installation complete!"
echo ""
echo "Next steps:"
echo "  1. Run 'ml4w-hyprland-setup' to configure Hyprland"
echo "  2. Reboot to start Hyprland automatically"
echo ""
echo "After reboot, Hyprland will start on TTY1."
echo "=============================================="
