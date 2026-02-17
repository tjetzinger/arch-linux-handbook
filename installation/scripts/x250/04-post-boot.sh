#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 4: Post-Boot Essentials (X250)
# ============================================================
# Run after first boot, as regular user with sudo access.
# Installs TLP, UFW, zram, Snapper, audio, fonts.
# ============================================================

set -e

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this script as root. Run as regular user with sudo access."
    exit 1
fi

echo "=============================================="
echo "Arch Linux Installation - Post-Boot (X250)"
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

# === TLP (power management) ===
echo "Installing TLP..."
sudo pacman -S --noconfirm tlp
sudo systemctl enable tlp
sudo systemctl start tlp

# === UFW (firewall) ===
echo "Setting up firewall..."
sudo pacman -S --noconfirm ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable
sudo systemctl enable ufw

# === zram ===
echo "Configuring zram..."
sudo pacman -S --noconfirm zram-generator

sudo mkdir -p /etc/systemd
cat << 'EOF' | sudo tee /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF

sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service

# === Snapper + snap-pac ===
echo "Setting up Snapper..."
sudo pacman -S --noconfirm snapper snap-pac

# Snapper subvolume dance
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

# === Audio ===
echo "Installing audio stack..."
sudo pacman -S --noconfirm --needed \
    pipewire pipewire-alsa pipewire-pulse wireplumber

systemctl --user enable pipewire pipewire-pulse wireplumber

# === Polkit ===
echo "Installing polkit..."
sudo pacman -S --noconfirm polkit-gnome

# === XDG ===
echo "Setting up XDG directories..."
sudo pacman -S --noconfirm xdg-user-dirs xdg-utils
xdg-user-dirs-update

# === Fonts ===
echo "Installing fonts..."
sudo pacman -S --noconfirm \
    ttf-jetbrains-mono-nerd \
    noto-fonts noto-fonts-emoji \
    ttf-firacode-nerd

echo ""
echo "=============================================="
echo "Post-boot setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run ./05-desktop.sh to install Niri + SDDM"
echo "=============================================="
