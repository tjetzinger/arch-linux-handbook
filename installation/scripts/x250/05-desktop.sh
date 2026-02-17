#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 5: Niri + SDDM (X250)
# ============================================================
# Run after 04-post-boot.sh, as regular user with sudo access.
# Installs Niri compositor, SDDM display manager, Sequoia theme.
# ============================================================

set -e

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this script as root. Run as regular user with sudo access."
    exit 1
fi

echo "=============================================="
echo "Arch Linux Installation - Niri + SDDM (X250)"
echo "=============================================="

# === Niri and tools ===
echo "Installing Niri and Wayland tools..."
yay -S --noconfirm --needed \
    niri waybar fuzzel dunst swaylock-effects swww wlogout \
    brightnessctl cliphist pamixer pwvucontrol swaybg swayidle \
    power-profiles-daemon polkit-gnome xwayland-satellite niriswitcher alacritty

# === Niri configuration (acaibowlz/niri-setup) ===
echo "Cloning niri-setup configuration..."
if [[ -d "$HOME/.config/niri-setup" ]]; then
    echo "niri-setup already exists, pulling latest..."
    git -C "$HOME/.config/niri-setup" pull
else
    git clone https://github.com/acaibowlz/niri-setup.git "$HOME/.config/niri-setup"
fi

# Create symlinks
echo "Setting up configuration symlinks..."
ln -sf "$HOME/.config/niri-setup/niri" "$HOME/.config/niri"
ln -sf "$HOME/.config/niri-setup/waybar" "$HOME/.config/waybar"
ln -sf "$HOME/.config/niri-setup/dunst" "$HOME/.config/dunst"
ln -sf "$HOME/.config/niri-setup/fuzzel" "$HOME/.config/fuzzel"
ln -sf "$HOME/.config/niri-setup/wlogout" "$HOME/.config/wlogout"
ln -sf "$HOME/.config/niri-setup/alacritty" "$HOME/.config/alacritty"
ln -sf "$HOME/.config/niri-setup/scripts" "$HOME/.config/niri-scripts"
ln -sf "$HOME/.config/niri-setup/niriswitcher" "$HOME/.config/niriswitcher"

# === NIRICONF environment variable ===
echo "Setting NIRICONF environment variable..."
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/niriconf.conf" << EOF
NIRICONF=/home/$USER/.config/niri-setup
EOF

# === SDDM ===
echo "Installing SDDM..."
sudo pacman -S --noconfirm --needed sddm qt6-declarative qt6-5compat
sudo systemctl enable sddm

# === Sequoia theme ===
echo "Installing Sequoia SDDM theme..."
if [[ -d /usr/share/sddm/themes/sequoia ]]; then
    echo "Sequoia theme already exists, pulling latest..."
    sudo git -C /usr/share/sddm/themes/sequoia pull
else
    sudo git clone https://codeberg.org/minMelody/sddm-sequoia.git \
        /usr/share/sddm/themes/sequoia
fi

# Set theme
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sequoia" | sudo tee /etc/sddm.conf.d/sddm.conf

# Fix 1: Icon font (theme ships with wrong default)
sudo sed -i 's/iconFont="Font Awesome 6 Free"/iconFont="FiraCode Nerd Font"/' \
    /usr/share/sddm/themes/sequoia/theme.conf

# Fix 2: PopupPanel delegate bug (breaks dropdowns)
sudo sed -i 's/delegate: menu.delegate//' \
    /usr/share/sddm/themes/sequoia/components/common/PopupPanel.qml

# === Final snapshot ===
echo "Creating snapshot..."
sudo snapper create -d "Niri + SDDM install complete"

echo ""
echo "=============================================="
echo "Desktop installation complete!"
echo ""
echo "Reboot to see the SDDM login screen."
echo "Select 'Niri' from the session dropdown."
echo ""
echo "Verification checklist:"
echo "  - systemctl --failed            (should be empty)"
echo "  - btrfs fi show                 (healthy filesystem)"
echo "  - snapper list                  (snapshots present)"
echo "  - cat /proc/swaps               (zram device)"
echo "  - sudo ufw status              (active)"
echo "  - tlp-stat -s                   (TLP active)"
echo "  - niri validate                 (no errors)"
echo "  - Mod+Return                    (opens Alacritty)"
echo "  - Mod+Space                     (opens Fuzzel)"
echo "=============================================="
