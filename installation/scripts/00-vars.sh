#!/bin/bash
# ============================================================
# Arch Linux Installation - Configuration Variables
# ============================================================
# Edit this file before running the installation scripts.
# All scripts source this file for configuration.
# ============================================================

# === DISK CONFIGURATION ===
DISK="/dev/nvme0n1"              # Target disk (check with: lsblk)
EFI_PART="${DISK}p1"             # EFI partition (p1 for NVMe, 1 for SATA)
ROOT_PART="${DISK}p2"            # Root partition
CRYPT_NAME="cryptroot"           # LUKS device mapper name

# === NETWORK ===
WIFI_SSID=""                     # Leave empty if using Ethernet
WIFI_PASS=""                     # WiFi password

# === LOCALE ===
TIMEZONE="Europe/Berlin"
LOCALE="en_US.UTF-8"
KEYMAP="de-latin1"               # Console keymap (us, de-latin1, etc.)
HOSTNAME="archlinux"

# === USER ===
USERNAME="tt"                    # Regular user to create
# Passwords will be prompted during installation

# === CPU ===
CPU_VENDOR="intel"               # intel or amd (for microcode)

# === SUBVOLUMES ===
# Btrfs subvolumes to create
SUBVOLUMES=(
    "@arch"          # Root
    "@.snapshots"    # Snapper
    "@home"          # Home
    "@log"           # /var/log
    "@cache"         # /var/cache
    "@tmp"           # /var/tmp
    "@vm"            # VMs
    "@arch-live"     # Recovery
)

# === MOUNT OPTIONS ===
MOUNT_OPTS="rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"
MOUNT_OPTS_NODATACOW="rw,noatime,nodatacow,ssd,discard=async,space_cache=v2"

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
)

# === MKINITCPIO ===
MKINITCPIO_MODULES="btrfs"
[[ "$CPU_VENDOR" == "intel" ]] && MKINITCPIO_MODULES="btrfs aesni_intel"

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
export WIFI_SSID WIFI_PASS
export TIMEZONE LOCALE KEYMAP HOSTNAME USERNAME CPU_VENDOR
export SUBVOLUMES MOUNT_OPTS MOUNT_OPTS_NODATACOW
export BASE_PACKAGES MKINITCPIO_MODULES MKINITCPIO_HOOKS
