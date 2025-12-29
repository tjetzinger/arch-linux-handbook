# 01 - Overview

Architecture and infrastructure for KVM/QEMU virtualization.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Applications                             │
│              (virt-manager, virsh, virt-viewer)             │
│                          ↓                                   │
│                      libvirtd                                │
│                          ↓                                   │
│                    QEMU/KVM                                  │
│         ┌────────────┼────────────┐                         │
│         ↓            ↓            ↓                         │
│      win11        arch         kali                         │
│     (16GB)       (2GB)        (2GB)                         │
│         │            │            │                         │
│         └────────────┼────────────┘                         │
│                      ↓                                       │
│              virbr0 (NAT)                                   │
│           192.168.122.0/24                                  │
└─────────────────────────────────────────────────────────────┘
```

## Components

### Hypervisor Stack

| Layer | Component | Purpose |
|-------|-----------|---------|
| Hardware | Intel VT-x | CPU virtualization support |
| Kernel | KVM | Kernel-based Virtual Machine |
| Emulator | QEMU | Hardware emulation |
| Management | libvirt | VM lifecycle management |
| Interface | virt-manager | GUI management |

### Installed Packages

```bash
# Core
qemu-full          # QEMU with all features
libvirt            # Virtualization API
virt-manager       # GUI manager
virt-viewer        # VM display client
virt-install       # CLI VM creation

# UEFI Support
edk2-ovmf          # UEFI firmware for VMs

# TPM Emulation
swtpm              # Software TPM emulator
libtpms            # TPM library
```

## Storage Layout

```
/mnt/vm/                    # Btrfs subvolume @vm
├── win11.qcow2             # Windows 11 disk (40GB)
├── win11_SECURE_VARS.fd    # Windows UEFI variables
├── kali-linux-*.qcow2      # Kali disk (33GB)
├── tpm/                    # TPM state for win11
├── iso/                    # ISO images
│   ├── Win11.iso
│   ├── archlinux-x86_64.iso
│   ├── kali-linux-*.iso
│   └── virtio-win.iso
└── swtpm-sock              # TPM socket

/var/lib/libvirt/
├── images/                 # Default image pool
│   └── arch-vm-minimal.qcow2
└── qemu/nvram/             # NVRAM storage
    └── arch_VARS.fd
```

## Network Topology

```
Internet
    │
    ├── wlan0 (192.168.178.x)     Host physical network
    │
    ├── tailscale0 (100.x.x.x)   Tailscale overlay
    │
    └── virbr0 (192.168.122.1)   VM NAT bridge
            │
            ├── win11 (192.168.122.136)
            ├── arch  (DHCP)
            └── kali  (DHCP)
```

### Network Access

| From | To | Method |
|------|----|--------|
| VM | Internet | NAT through virbr0 |
| VM | Host | Direct (192.168.122.1) |
| VM | Tailnet | Through host's Tailscale |
| Remote | VM | Tailscale subnet routing (192.168.122.0/24) |

## Resource Allocation

### Host System

| Resource | Total | Available for VMs |
|----------|-------|-------------------|
| CPU | 20 threads | ~14 threads |
| RAM | 64GB | ~48GB |
| Storage | 2TB NVMe | ~1.5TB |

### Current Allocation

| VM | vCPUs | RAM | Disk |
|----|-------|-----|------|
| win11 | 6 (pinned) | 16GB | 40GB |
| arch | 2 | 2GB | 69GB |
| kali | 2 | 2GB | 33GB |
| **Total** | 10 | 20GB | 142GB |

## Feature Matrix

| Feature | win11 | arch | kali |
|---------|-------|------|------|
| UEFI Boot | Yes | Yes | No (BIOS) |
| Secure Boot | Yes | Yes | No |
| TPM 2.0 | Yes | No | No |
| virtio disk | Yes | Yes | Yes |
| virtio network | Yes | Yes | Yes |
| SPICE display | Yes | Yes | Yes |
| virtiofs | Yes | No | No |
| CPU pinning | Yes | No | No |

## Services

### Enabled Services

```bash
# Check status
systemctl status libvirtd

# Enabled units
libvirtd.service          # Main daemon
libvirtd.socket           # Socket activation
libvirtd-ro.socket        # Read-only socket
libvirtd-admin.socket     # Admin socket
virtlockd.socket          # Lock daemon
virtlogd.socket           # Log daemon
```

### Service Architecture

```
libvirtd (monolithic)
    ├── Manages VMs
    ├── Manages networks
    ├── Manages storage
    └── Spawns QEMU processes

dnsmasq (spawned by libvirt)
    ├── DHCP for virbr0
    └── DNS for VMs
```

## File Locations

| Purpose | Location |
|---------|----------|
| VM definitions | `/etc/libvirt/qemu/` |
| Network definitions | `/etc/libvirt/qemu/networks/` |
| Storage pool definitions | `/etc/libvirt/storage/` |
| QEMU config | `/etc/libvirt/qemu.conf` |
| libvirt config | `/etc/libvirt/libvirtd.conf` |
| Logs | `/var/log/libvirt/qemu/` |
| Runtime | `/run/libvirt/` |

## Quick Commands

```bash
# VM Management
virsh list --all              # List all VMs
virsh start <vm>              # Start VM
virsh shutdown <vm>           # Graceful shutdown
virsh destroy <vm>            # Force stop
virsh reboot <vm>             # Reboot VM

# Information
virsh dominfo <vm>            # VM details
virsh domblklist <vm>         # List disks
virsh domiflist <vm>          # List network interfaces
virsh vcpuinfo <vm>           # CPU info

# Network
virsh net-list --all          # List networks
virsh net-dhcp-leases default # Show DHCP leases

# Storage
virsh pool-list --all         # List storage pools
virsh vol-list <pool>         # List volumes in pool
```

## Related

- [02-LIBVIRT-SETUP](./02-LIBVIRT-SETUP.md) - Detailed setup
- [06-NETWORKING](./06-NETWORKING.md) - Network configuration
- [07-STORAGE](./07-STORAGE.md) - Storage management
