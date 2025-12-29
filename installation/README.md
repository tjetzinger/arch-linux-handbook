# Arch Linux Installation Guide

Complete guide for installing Arch Linux with modern security and recovery features.

## Target System

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Bootloader | systemd-boot | Native systemd integration, simple |
| Encryption | LUKS2 + keyfile | Strong encryption + auto-unlock |
| Filesystem | Btrfs | Snapshots, compression, modern |
| Init hooks | systemd | Modern, faster boot |
| Snapshots | Snapper + snap-pac | Automatic pre/post package snapshots |
| Desktop | Hyprland (ml4w) | Modern Wayland compositor |

## Features

- **Full disk encryption** with LUKS2 (argon2id)
- **Automatic unlock** via keyfile with password fallback
- **Btrfs subvolumes** for flexible snapshot management
- **Snapper integration** from initial setup
- **Multiple kernels** (linux + linux-lts) for fallback
- **Recovery environment** (arch-live) on same disk
- **Organized EFI structure** (`/EFI/arch/`)

---

## Documentation

### Installation Steps

| # | Document | Description |
|---|----------|-------------|
| 01 | [PREPARATION.md](./01-PREPARATION.md) | Pre-install checklist, create USB, verify hardware |
| 02 | [DISK-SETUP.md](./02-DISK-SETUP.md) | Partitioning, LUKS encryption, Btrfs subvolumes |
| 03 | [BASE-INSTALL.md](./03-BASE-INSTALL.md) | pacstrap, fstab, chroot, basic config |
| 04 | [BOOTLOADER.md](./04-BOOTLOADER.md) | systemd-boot, mkinitcpio, LUKS keyfile |
| 05 | [SYSTEM-CONFIG.md](./05-SYSTEM-CONFIG.md) | Locale, users, network, essential services |
| 06 | [SNAPPER-SETUP.md](./06-SNAPPER-SETUP.md) | Snapper configuration, snap-pac, automation |
| 07 | [DESKTOP-HYPRLAND.md](./07-DESKTOP-HYPRLAND.md) | Hyprland via ml4w, Wayland essentials |
| 08 | [POST-INSTALL.md](./08-POST-INSTALL.md) | Essential packages, AUR, dotfiles, hardening |

### Scripts

Automated installation scripts in [`scripts/`](./scripts/):

| Script | Purpose |
|--------|---------|
| `00-vars.sh` | Configuration variables (edit this first) |
| `01-partition.sh` | Disk partitioning and encryption |
| `02-install.sh` | Base system installation |
| `03-configure.sh` | System configuration in chroot |
| `04-desktop.sh` | Desktop environment setup |

---

## Quick Start

### Manual Installation
Follow documents 01-08 in order.

### Semi-Automated
```bash
# 1. Boot Arch ISO
# 2. Connect to internet
# 3. Clone this repo
git clone https://github.com/youruser/arch-linux-guides
cd arch-linux-guides/installation/scripts

# 4. Edit configuration
vim 00-vars.sh

# 5. Run scripts in order
./01-partition.sh
./02-install.sh
./03-configure.sh
# Reboot, then run:
./04-desktop.sh
```

---

## Hardware Reference

This guide was created for and tested on:

| Component | Specification |
|-----------|---------------|
| Model | Lenovo ThinkPad X1 Carbon |
| CPU | Intel (with AES-NI) |
| Storage | NVMe SSD |
| Graphics | Intel integrated |
| Firmware | UEFI with Secure Boot support |

Adjustments may be needed for AMD CPUs, NVIDIA GPUs, or different hardware.

---

## Subvolume Layout

```
Btrfs filesystem (on LUKS)
├── @arch        → /              # Main system (snapshotted)
├── @.snapshots  → /.snapshots    # Snapper snapshots
├── @home        → /home          # User data (optional separate)
├── @log         → /var/log       # Logs (excluded from snapshots)
├── @cache       → /var/cache     # Cache (excluded from snapshots)
├── @vm          → /mnt/vm        # VMs (nodatacow)
└── @arch-live   → /mnt/arch-live # Recovery environment
```

---

## Related Documentation

- [System Recovery](../system-recovery/) - Recovery procedures, snapper usage, disaster recovery
- [Arch Wiki](https://wiki.archlinux.org/) - Official documentation
