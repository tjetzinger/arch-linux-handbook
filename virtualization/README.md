# Virtualization

KVM/QEMU virtualization with libvirt on Arch Linux.

## Current Setup

| Component | Details |
|-----------|---------|
| Hypervisor | libvirt + QEMU/KVM |
| Manager | virt-manager |
| Storage | Btrfs subvolume `@vm` at `/mnt/vm` |
| Network | NAT (virbr0) - 192.168.122.0/24 |

## Virtual Machines

| VM | OS | RAM | vCPUs | State |
|----|-----|-----|-------|-------|
| win11 | Windows 11 | 16GB | 6 | Primary workstation |
| arch | Arch Linux | 2GB | 2 | Testing |
| kali | Kali Linux | 2GB | 2 | Security testing |

## Host Resources

| Resource | Available |
|----------|-----------|
| CPU | Intel i7-1370P (20 threads, VT-x) |
| RAM | 64GB |
| GPU | Intel Iris Xe (no passthrough) |

## Quick Reference

```bash
# List VMs
virsh list --all

# Start/Stop VM
virsh start win11
virsh shutdown win11

# Connect to VM display
virt-viewer win11

# Open virt-manager
virt-manager
```

## Documentation

| Document | Description |
|----------|-------------|
| [01-OVERVIEW](./01-OVERVIEW.md) | Architecture and infrastructure |
| [02-LIBVIRT-SETUP](./02-LIBVIRT-SETUP.md) | Service and permission setup |
| [03-CREATING-VMS](./03-CREATING-VMS.md) | VM creation methods |
| [04-WINDOWS-VM](./04-WINDOWS-VM.md) | Windows 11 with TPM/Secure Boot |
| [05-LINUX-VMS](./05-LINUX-VMS.md) | Arch and Kali VM setup |
| [06-NETWORKING](./06-NETWORKING.md) | VM networking options |
| [07-STORAGE](./07-STORAGE.md) | Disk images and snapshots |
| [08-PERFORMANCE](./08-PERFORMANCE.md) | Optimization and tuning |
| [09-TROUBLESHOOTING](./09-TROUBLESHOOTING.md) | Common issues and fixes |

## Related

- [Networking - Tailscale Integration](../networking/05-NETWORK-INTEGRATION.md#libvirtkvm-integration)
