# Arch Linux Handbook

Comprehensive documentation for Arch Linux installation, configuration, and maintenance on modern hardware.

## About

This repository contains battle-tested guides covering:

- **Full-disk encryption** with LUKS2 + Btrfs + systemd-boot
- **Automated snapshots** with Snapper for easy rollback
- **Disaster recovery** procedures and backup strategies
- **Networking** with Tailscale VPN and Mullvad exit nodes
- **Virtualization** using KVM/QEMU with libvirt
- **Containers** with Docker and Traefik reverse proxy
- **Hyprland** desktop environment configuration
- **Hardware optimization** for ThinkPad X1 Carbon Gen 11

All documentation follows a practical, command-first approach with copy-paste ready examples.

## Contents

| Directory | Description |
|-----------|-------------|
| [installation/](./installation/) | Complete Arch Linux installation guide with scripts |
| [system-recovery/](./system-recovery/) | Recovery, backup, and maintenance guides |
| [networking/](./networking/) | Tailscale, DNS, and network configuration |
| [virtualization/](./virtualization/) | KVM/QEMU virtual machines with libvirt |
| [docker/](./docker/) | Docker containers with Traefik reverse proxy |
| [systemd/](./systemd/) | Systemd services, timers, and configuration |
| [hardware/](./hardware/) | ThinkPad X1 Carbon Gen 11 hardware configuration |
| [desktop/](./desktop/) | Hyprland/ML4W desktop environment configuration |
| [applications/](./applications/) | Applications and configurations |
| [scripts/](./scripts/) | Hyprland automation scripts |

## System Stack

| Component | Choice |
|-----------|--------|
| **OS** | Arch Linux |
| **Filesystem** | Btrfs on LUKS2 |
| **Bootloader** | systemd-boot |
| **Encryption** | LUKS2 with keyfile auto-unlock |
| **Snapshots** | Snapper + snap-pac |
| **Backup** | Borg, rclone |
| **Desktop** | Hyprland (ML4W) |
| **VPN** | Tailscale + Mullvad |
| **Virtualization** | KVM/QEMU + libvirt |
| **Containers** | Docker + Traefik |
| **Init System** | systemd + TLP |
| **Hardware** | ThinkPad X1 Carbon Gen 11 |

## Quick Start

### Fresh Installation
Follow the [Installation Guide](./installation/README.md) for a complete Arch Linux setup with LUKS encryption and Btrfs.

### System Recovery
See [System Recovery](./system-recovery/README.md) for snapshot rollback and disaster recovery procedures.

### Networking
See [Networking](./networking/README.md) for Tailscale VPN and DNS configuration.

### Virtualization
See [Virtualization](./virtualization/README.md) for KVM/QEMU setup and Windows 11 VMs.

### Docker
See [Docker](./docker/README.md) for container infrastructure with Traefik reverse proxy.

## Documentation Index

### Installation (./installation/)
| Document | Description |
|----------|-------------|
| 01-PREPARATION | Pre-install checklist |
| 02-DISK-SETUP | LUKS + Btrfs partitioning |
| 03-BASE-INSTALL | Base system installation |
| 04-BOOTLOADER | systemd-boot + keyfile |
| 05-SYSTEM-CONFIG | System configuration |
| 06-SNAPPER-SETUP | Snapshot configuration |
| 07-DESKTOP-HYPRLAND | Hyprland/ML4W setup |
| 08-POST-INSTALL | Final configuration |

### System Recovery (./system-recovery/)
| Document | Description |
|----------|-------------|
| 01-MANUAL-ARCH-LIVE-RECOVERY | Emergency boot recovery |
| 02-SNAPPER-SYSTEMD-BOOT | Snapshot boot entries |
| 03-SNAPPER-DAILY-USAGE | Common snapper commands |
| 04-BACKUP-STRATEGY-OVERVIEW | Backup infrastructure |
| 05-LUKS-KEY-MANAGEMENT | Encryption management |
| 06-BTRFS-MAINTENANCE | Filesystem maintenance |
| 07-BORG-BACKUP-AUTOMATION | Automated backups |
| 08-DISASTER-RECOVERY-CHECKLIST | Recovery scenarios |
| 09-SUBVOLUME-STRATEGY | Btrfs layout planning |
| 10-BOOT-PARTITION-BACKUP | /boot backup |

### Networking (./networking/)
| Document | Description |
|----------|-------------|
| 01-TAILSCALE-SETUP | Installation and basic configuration |
| 02-EXIT-NODES-MULLVAD | Mullvad VPN integration |
| 03-DNS-CONFIGURATION | systemd-resolved + MagicDNS |
| 04-SUBNET-ROUTING | Remote LAN access setup |
| 05-NETWORK-INTEGRATION | Docker, libvirt, NetworkManager |
| 06-TROUBLESHOOTING | Common issues and debugging |

### Virtualization (./virtualization/)
| Document | Description |
|----------|-------------|
| 01-OVERVIEW | Architecture and infrastructure |
| 02-LIBVIRT-SETUP | Service and permission setup |
| 03-CREATING-VMS | VM creation methods |
| 04-WINDOWS-VM | Windows 11 with TPM/Secure Boot |
| 05-LINUX-VMS | Arch and Kali VM setup |
| 06-NETWORKING | VM networking options |
| 07-STORAGE | Disk images and snapshots |
| 08-PERFORMANCE | Optimization and tuning |
| 09-TROUBLESHOOTING | Common issues and fixes |

### Docker (./docker/)
| Document | Description |
|----------|-------------|
| 01-OVERVIEW | Container architecture |
| 02-DOCKER-SETUP | Installation and configuration |
| 03-TRAEFIK | Reverse proxy and SSL |
| 04-AI-STACK | Ollama, Open WebUI, LiteLLM |
| 05-SERVICES | n8n, Portainer, Watchtower |
| 06-NETWORKING | Docker networks |
| 07-STORAGE | Volumes and persistence |
| 08-SECURITY | SSL, auth, hardening |
| 09-MAINTENANCE | Updates and troubleshooting |

### Systemd (./systemd/)
| Document | Description |
|----------|-------------|
| 01-OVERVIEW | Systemd basics and architecture |
| 02-CORE-SERVICES | journald, resolved, timesyncd |
| 03-NETWORK-SERVICES | NetworkManager, Tailscale, SSH |
| 04-POWER-MANAGEMENT | TLP, cpupower, laptop-mode |
| 05-TIMERS | Snapper, reflector, fstrim |
| 06-SECURITY | UFW firewall configuration |
| 07-DESKTOP-SERVICES | SDDM, PipeWire, user services |
| 08-HARDWARE | Bluetooth, CUPS, Logitech |
| 09-TROUBLESHOOTING | journalctl and debugging |

### Hardware (./hardware/)
| Document | Description |
|----------|-------------|
| 01-OVERVIEW | ThinkPad X1 Carbon Gen 11 specifications |
| 02-POWER-BATTERY | TLP, charge thresholds, battery health |
| 03-INPUT-DEVICES | TrackPoint, touchpad, keyboard |
| 04-DISPLAY-GRAPHICS | Intel Iris Xe, VA-API, external monitors |
| 05-AUDIO | PipeWire, Intel HDA configuration |
| 06-NETWORKING-HW | WiFi 6E (AX211), Bluetooth |
| 07-BIOMETRICS | Fingerprint reader (Synaptics) |
| 08-PERIPHERALS | Logitech mice, Yubikey |
| 09-FIRMWARE | BIOS updates via fwupd |

### Desktop (./desktop/)
| Document | Description |
|----------|-------------|
| 01-OVERVIEW | ML4W dotfiles and Hyprland architecture |
| 02-CONFIGURATION | Config file structure and sourcing |
| 03-KEYBINDINGS | Keyboard shortcuts reference |
| 04-MONITORS | Display configuration and profiles |
| 05-WAYBAR | Status bar configuration |
| 06-LAUNCHERS | Rofi, cliphist, wlogout |
| 07-NOTIFICATIONS | SwayNC notification center |
| 08-LOCKSCREEN | hyprlock and hypridle |
| 09-THEMING | Colors, wallpapers, pywal |
| 10-TERMINALS | Terminal emulators |
| 11-CUSTOMIZATION | Adding custom configurations |
| 12-KEYRING | GNOME Keyring credential storage |

### Applications (./applications/)
| Document | Description |
|----------|-------------|
| 01-OVERVIEW | Application inventory and config locations |
| 02-BROWSERS | Chrome, Firefox |
| 03-NEOVIM | Neovim with Lazy.nvim |
| 04-EDITORS | VS Code, Cursor |
| 05-FILE-MANAGERS | Nautilus, Superfile |
| 06-MEDIA | VLC, mpv, GIMP, yt-dlp |
| 07-SHELL | Zsh, oh-my-zsh, oh-my-posh |
| 08-GIT-SSH | Git, GitHub CLI, SSH profiles |
| 09-DEV-TOOLS | Python, Node.js, Rust, Go |
| 10-AI-TOOLS | LM Studio, ChatBox, MCP |
| 11-REMOTE | Remmina, remote access |
| 12-DOTFILES | Dotfiles structure and management |
| 13-ANDROID | Waydroid Android container |

### Scripts (./scripts/)
| Document | Description |
|----------|-------------|
| 01-OVERVIEW | Complete script inventory |
| 02-DESKTOP-CONTROL | Power management, screenshots |
| 03-WALLPAPER-THEMING | Wallpaper, effects, game mode |
| 04-MONITORS | Monitor management, dock/undock |
| 05-UTILITIES | XDG portal, GTK sync, config reload |
| 06-CUSTOMIZATION | Creating custom scripts |

## Usage Notes

- **UUIDs**: Documents use placeholders like `<LUKS-UUID>`, `<EFI-UUID>` - replace with your actual partition UUIDs
- **Paths**: Home directory paths use `~` - expand to your actual home directory
- **Hardware**: While optimized for ThinkPad X1 Carbon Gen 11, most guides apply to any Arch Linux system

## Contributing

Found an error or have improvements? Contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This documentation is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

You are free to:
- **Share** - copy and redistribute the material
- **Adapt** - remix, transform, and build upon the material

Under the following terms:
- **Attribution** - give appropriate credit
- **ShareAlike** - distribute contributions under the same license
