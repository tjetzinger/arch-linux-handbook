#!/bin/bash
# ============================================================
# Arch Linux Installation - Configuration Variables (X250)
# ============================================================
# Forked from ../00-vars.sh for ThinkPad X250
# Broadwell dual-core, 8GB DDR3L, SATA SSD
# ============================================================

# === DISK CONFIGURATION ===
DISK="/dev/sda"                  # SATA SSD (check with: lsblk)
EFI_PART="${DISK}1"              # EFI partition (no 'p' prefix for SATA)
ROOT_PART="${DISK}2"             # Root partition
CRYPT_NAME="cryptroot"           # LUKS device mapper name

# === LUKS TUNING (X250 hardware) ===
LUKS_PBKDF_MEMORY=524288         # 512 MiB (halved for 8GB RAM)
LUKS_PBKDF_PARALLEL=2            # Broadwell is dual-core

# === NETWORK ===
WIFI_SSID=""                     # Leave empty if using Ethernet
WIFI_PASS=""                     # WiFi password

# === LOCALE ===
TIMEZONE="Europe/Berlin"
LOCALE="en_US.UTF-8"
KEYMAP="de-latin1"               # Console keymap (us, de-latin1, etc.)
HOSTNAME="x250"

# === USER ===
USERNAME="tt"                    # Regular user to create
# Passwords will be prompted during installation

# === CPU ===
CPU_VENDOR="intel"               # intel or amd (for microcode)

# === SUBVOLUMES ===
# Btrfs subvolumes to create (no @vm or @arch-live for X250)
SUBVOLUMES=(
    "@arch"          # Root
    "@.snapshots"    # Snapper
    "@home"          # Home
    "@log"           # /var/log
    "@cache"         # /var/cache
    "@tmp"           # /var/tmp
)

# === MOUNT OPTIONS ===
MOUNT_OPTS="rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

# === PACKAGES ===
# Base packages for installation
BASE_PACKAGES=(
    base
    linux
    linux-lts
    linux-firmware
    "${CPU_VENDOR}-ucode"
    btrfs-progs
    networkmanager
    vim
    sudo
    base-devel
    git
    openssh
    man-db
    man-pages
)

# === MKINITCPIO ===
MKINITCPIO_MODULES="btrfs aesni_intel"

MKINITCPIO_HOOKS="base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck"

# ============================================================
# END OF CONFIGURATION
# ============================================================

# Validation
validate_config() {
    local errors=0

    [[ ! -b "$DISK" ]] && echo "ERROR: Disk $DISK not found" && ((errors++))
    [[ -z "$HOSTNAME" ]] && echo "ERROR: HOSTNAME not set" && ((errors++))
    [[ -z "$USERNAME" ]] && echo "ERROR: USERNAME not set" && ((errors++))
    [[ ! "$CPU_VENDOR" =~ ^(intel|amd)$ ]] && echo "ERROR: CPU_VENDOR must be intel or amd" && ((errors++))

    return $errors
}

# Export for use in scripts
export DISK EFI_PART ROOT_PART CRYPT_NAME
export LUKS_PBKDF_MEMORY LUKS_PBKDF_PARALLEL
export WIFI_SSID WIFI_PASS
export TIMEZONE LOCALE KEYMAP HOSTNAME USERNAME CPU_VENDOR
export SUBVOLUMES MOUNT_OPTS
export BASE_PACKAGES MKINITCPIO_MODULES MKINITCPIO_HOOKS
