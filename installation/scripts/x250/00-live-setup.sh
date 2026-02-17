#!/bin/bash
# ============================================================
# Arch Linux Installation - Step 0: Live Environment (X250)
# ============================================================
# Run this on the X250 after booting the USB stick.
# Sets up keyboard, SSH, and prints the IP for remote access.
# Then SSH in from X1: ssh root@<ip>
# ============================================================

set -e

echo "=============================================="
echo "Arch Linux Live Environment Setup (X250)"
echo "=============================================="

# === Keyboard layout ===
echo "Setting keyboard layout to de-latin1..."
loadkeys de-latin1

# === Root password for SSH ===
echo ""
echo "Set a temporary root password for SSH access:"
passwd

# === Enable SSH ===
echo "Enabling SSH..."
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl start sshd

# === Show IP ===
echo ""
echo "=============================================="
echo "SSH ready. Connect from X1 with:"
echo ""
ip -4 addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | while read -r ip; do
    echo "  ssh root@$ip"
done
echo ""
echo "Then run: ./01-partition.sh"
echo "=============================================="
