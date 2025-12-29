# 02 - libvirt Setup

Service configuration, user permissions, and storage pools.

## Installation

### Required Packages

```bash
# Core packages
sudo pacman -S qemu-full libvirt virt-manager virt-viewer virt-install

# UEFI support
sudo pacman -S edk2-ovmf

# TPM emulation (for Windows 11)
sudo pacman -S swtpm

# Optional: additional tools
sudo pacman -S libvirt-python libvirt-glib
```

### Package Groups

```bash
# Install everything at once
sudo pacman -S qemu-full libvirt virt-manager edk2-ovmf swtpm
```

## Service Configuration

### Enable Services

```bash
# Enable and start libvirtd
sudo systemctl enable --now libvirtd.service

# Socket activation (recommended)
sudo systemctl enable libvirtd.socket
sudo systemctl enable libvirtd-ro.socket
sudo systemctl enable libvirtd-admin.socket

# Lock and log daemons
sudo systemctl enable virtlockd.socket
sudo systemctl enable virtlogd.socket
```

### Verify Service

```bash
# Check status
systemctl status libvirtd

# Check socket
systemctl status libvirtd.socket

# View logs
journalctl -u libvirtd -f
```

## User Permissions

### Add User to libvirt Group

```bash
# Add current user to libvirt group
sudo usermod -aG libvirt $USER

# Verify
groups $USER
# Should show: tt wheel docker libvirt ...

# Log out and back in for group changes
```

### Verify Access

```bash
# Test connection (as regular user)
virsh -c qemu:///system list --all

# Should work without sudo
virt-manager
```

## Default Network

### Enable Default Network

```bash
# Start default network
sudo virsh net-start default

# Auto-start on boot
sudo virsh net-autostart default

# Verify
virsh net-list --all
```

### Default Network Configuration

```xml
<!-- /etc/libvirt/qemu/networks/default.xml -->
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

### Check DHCP Leases

```bash
virsh net-dhcp-leases default
```

## Storage Pools

### Current Pools

| Pool | Type | Path | Purpose |
|------|------|------|---------|
| default | dir | /var/lib/libvirt/images | Default images |
| vm | dir | /mnt/vm | Main VM storage |
| iso | dir | /mnt/vm/iso | ISO images |
| nvram | dir | /var/lib/libvirt/qemu/nvram | UEFI variables |

### Create Storage Pool

```bash
# Create directory pool
virsh pool-define-as vm dir --target /mnt/vm

# Start pool
virsh pool-start vm

# Auto-start on boot
virsh pool-autostart vm

# Verify
virsh pool-list --all
virsh pool-info vm
```

### Pool for ISO Images

```bash
# Create ISO pool
virsh pool-define-as iso dir --target /mnt/vm/iso
virsh pool-start iso
virsh pool-autostart iso

# Refresh to detect ISOs
virsh pool-refresh iso
virsh vol-list iso
```

### Pool XML Example

```xml
<!-- vm pool definition -->
<pool type='dir'>
  <name>vm</name>
  <target>
    <path>/mnt/vm</path>
    <permissions>
      <mode>0755</mode>
      <owner>1000</owner>
      <group>1000</group>
    </permissions>
  </target>
</pool>
```

## QEMU Configuration

### User/Group Settings

**File:** `/etc/libvirt/qemu.conf`

```bash
# Run QEMU as current user (optional)
# Uncomment and set:
user = "tt"
group = "libvirt"

# Or use dynamic (default)
# user = "+959"
# group = "+959"
```

### Security Settings

```bash
# In /etc/libvirt/qemu.conf

# SELinux/AppArmor (if applicable)
security_driver = "none"

# NVRAM paths for UEFI
nvram = [
    "/usr/share/edk2/x64/OVMF_CODE.fd:/usr/share/edk2/x64/OVMF_VARS.fd",
    "/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd:/usr/share/edk2/x64/OVMF_VARS.4m.fd"
]
```

### Apply Changes

```bash
sudo systemctl restart libvirtd
```

## Kernel Modules

### Verify KVM

```bash
# Check KVM modules
lsmod | grep kvm

# Expected output:
# kvm_intel    ...
# kvm          ...

# Check virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0
```

### Load Modules (if needed)

```bash
# Load KVM modules
sudo modprobe kvm
sudo modprobe kvm_intel  # For Intel CPUs

# Make persistent
echo "kvm" | sudo tee /etc/modules-load.d/kvm.conf
echo "kvm_intel" | sudo tee -a /etc/modules-load.d/kvm.conf
```

## IP Forwarding

### Enable for VM Networking

```bash
# Check current status
cat /proc/sys/net/ipv4/ip_forward
# Should be 1

# Enable if needed
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-libvirt.conf
sudo sysctl -p /etc/sysctl.d/99-libvirt.conf
```

## Polkit Rules

### Allow libvirt Group Access

**File:** `/etc/polkit-1/rules.d/50-libvirt.rules`

```javascript
/* Allow users in libvirt group to manage VMs without password */
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

## Verify Installation

### Complete Check

```bash
# 1. Service running
systemctl is-active libvirtd

# 2. User in group
groups | grep libvirt

# 3. Can connect
virsh -c qemu:///system list

# 4. Network active
virsh net-list --all

# 5. Storage pools
virsh pool-list --all

# 6. KVM available
virsh capabilities | grep -i kvm
```

### Test VM Creation

```bash
# Quick test with virt-install
virt-install --name test \
    --memory 512 \
    --vcpus 1 \
    --disk none \
    --boot cdrom \
    --osinfo generic \
    --transient \
    --destroy-on-exit
# Press Ctrl+C to exit
```

## Troubleshooting

### Permission Denied

```bash
# Check group membership
groups $USER

# Re-login or use newgrp
newgrp libvirt

# Check socket permissions
ls -la /var/run/libvirt/libvirt-sock
```

### Network Not Starting

```bash
# Check for conflicts
sudo ss -tlnp | grep 53

# Restart network
sudo virsh net-destroy default
sudo virsh net-start default

# Check dnsmasq
ps aux | grep dnsmasq
```

### QEMU Permission Issues

```bash
# Check ownership of VM files
ls -la /mnt/vm/

# Fix if needed
sudo chown -R libvirt-qemu:libvirt-qemu /mnt/vm/*.qcow2
```

## Quick Reference

```bash
# Service
sudo systemctl restart libvirtd
journalctl -u libvirtd -f

# Networks
virsh net-list --all
virsh net-start default

# Storage
virsh pool-list --all
virsh pool-refresh vm

# User access
sudo usermod -aG libvirt $USER
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Architecture overview
- [03-CREATING-VMS](./03-CREATING-VMS.md) - Creating VMs
