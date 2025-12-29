# 05 - Linux VMs

Setup and configuration for Arch Linux and Kali Linux virtual machines.

## Current VMs

| VM | OS | RAM | vCPUs | Disk | Boot |
|----|-----|-----|-------|------|------|
| arch | Arch Linux | 2GB | 2 | 69GB | UEFI + Secure Boot |
| kali | Kali Linux | 2GB | 2 | 33GB | BIOS |

## Arch Linux VM

### Current Configuration

| Setting | Value |
|---------|-------|
| Firmware | UEFI with Secure Boot |
| Disk | /var/lib/libvirt/images/arch-vm-minimal.qcow2 |
| Network | virtio on default NAT |
| Display | SPICE |

### Create New Arch VM

```bash
virt-install \
    --name arch \
    --title "Arch Linux" \
    --memory 2048 \
    --vcpus 2 \
    --cpu host-passthrough \
    --disk path=/mnt/vm/arch.qcow2,size=20,format=qcow2,bus=virtio \
    --cdrom /mnt/vm/iso/archlinux-x86_64.iso \
    --network network=default,model=virtio \
    --graphics spice \
    --video virtio \
    --channel spicevmc \
    --boot uefi \
    --os-variant archlinux
```

### With Secure Boot

```bash
virt-install \
    --name arch-secboot \
    --memory 2048 \
    --vcpus 2 \
    --disk size=20,bus=virtio \
    --cdrom /mnt/vm/iso/archlinux-x86_64.iso \
    --network network=default,model=virtio \
    --graphics spice \
    --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes \
    --features smm.state=on \
    --os-variant archlinux
```

### Installation Tips

1. **Boot the ISO**
2. **Set keyboard**: `loadkeys de-latin1`
3. **Partition with GPT** (for UEFI):
   ```bash
   fdisk /dev/vda
   # Create GPT, EFI partition (512M), root partition
   ```
4. **Install base**:
   ```bash
   pacstrap /mnt base linux linux-firmware
   ```
5. **Install guest tools**:
   ```bash
   pacman -S qemu-guest-agent spice-vdagent
   systemctl enable qemu-guest-agent
   systemctl enable spice-vdagentd
   ```

### Guest Packages

```bash
# Essential for VM
pacman -S qemu-guest-agent spice-vdagent

# Enable services
systemctl enable --now qemu-guest-agent
systemctl enable --now spice-vdagentd
```

### Benefits of Guest Agent

- `virsh shutdown` works properly
- Host can query guest info
- File system freeze for snapshots
- Time synchronization

## Kali Linux VM

### Current Configuration

| Setting | Value |
|---------|-------|
| Firmware | BIOS (legacy) |
| Disk | /mnt/vm/kali-linux-2024.4-qemu-amd64.qcow2 |
| Network | virtio on default NAT |

### Using Pre-built Image

Kali provides ready-to-use QEMU images:

1. Download from: https://www.kali.org/get-kali/#kali-virtual-machines
2. Choose "QEMU" version
3. Extract the qcow2 file

```bash
# Import existing Kali image
virt-install \
    --name kali \
    --title "Kali Linux" \
    --memory 2048 \
    --vcpus 2 \
    --cpu host-passthrough \
    --disk /mnt/vm/kali-linux-2024.4-qemu-amd64.qcow2,bus=virtio \
    --import \
    --network network=default,model=virtio \
    --graphics spice \
    --os-variant debian11
```

### Fresh Installation

```bash
virt-install \
    --name kali-fresh \
    --memory 4096 \
    --vcpus 2 \
    --disk size=40,bus=virtio \
    --cdrom /mnt/vm/iso/kali-linux-installer-amd64.iso \
    --network network=default,model=virtio \
    --graphics spice \
    --os-variant debian11
```

### Default Credentials (Pre-built)

- Username: `kali`
- Password: `kali`

**Change immediately after first login!**

### Guest Tools in Kali

```bash
# Install guest packages
sudo apt update
sudo apt install spice-vdagent qemu-guest-agent

# Enable services
sudo systemctl enable --now qemu-guest-agent
sudo systemctl enable --now spice-vdagentd
```

## Cloud-Init VMs

### Create Cloud-Init Enabled VM

For automated provisioning:

```bash
# Download cloud image
wget https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2

# Create VM with cloud-init
virt-install \
    --name arch-cloud \
    --memory 2048 \
    --vcpus 2 \
    --disk Arch-Linux-x86_64-cloudimg.qcow2 \
    --import \
    --cloud-init user-data=user-data.yaml \
    --network network=default \
    --os-variant archlinux
```

### Sample user-data.yaml

```yaml
#cloud-config
hostname: arch-vm
users:
  - name: user
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAA... your-key
packages:
  - qemu-guest-agent
  - vim
runcmd:
  - systemctl enable --now qemu-guest-agent
```

## Minimal Server VM

### Headless Arch Server

```bash
virt-install \
    --name arch-server \
    --memory 1024 \
    --vcpus 1 \
    --disk size=10,bus=virtio \
    --location /mnt/vm/iso/archlinux-x86_64.iso \
    --network network=default,model=virtio \
    --graphics none \
    --console pty,target_type=serial \
    --extra-args 'console=ttyS0,115200n8' \
    --os-variant archlinux
```

### Connect to Console

```bash
virsh console arch-server
# Exit with Ctrl+]
```

## Shared Folders

### virtiofs (Recommended)

```bash
# Add in virt-manager or XML:
virsh edit arch
```

```xml
<memoryBacking>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>

<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs'/>
  <source dir='/home/tt/shared'/>
  <target dir='shared'/>
</filesystem>
```

Mount in guest:
```bash
sudo mount -t virtiofs shared /mnt/shared
```

### 9p Filesystem (Alternative)

```xml
<filesystem type='mount' accessmode='mapped'>
  <source dir='/home/tt/shared'/>
  <target dir='shared'/>
</filesystem>
```

Mount in guest:
```bash
sudo mount -t 9p -o trans=virtio shared /mnt/shared
```

## Network Configuration

### Static IP in Guest

```bash
# Using systemd-networkd
cat > /etc/systemd/network/20-wired.network << EOF
[Match]
Name=en*

[Network]
Address=192.168.122.100/24
Gateway=192.168.122.1
DNS=192.168.122.1
EOF

systemctl enable --now systemd-networkd
```

### DHCP (Default)

```bash
# NetworkManager
nmcli device connect ens3

# systemd-networkd
cat > /etc/systemd/network/20-wired.network << EOF
[Match]
Name=en*

[Network]
DHCP=yes
EOF
```

## Performance Optimization

### VirtIO Drivers

Always use VirtIO for best performance:
- Disk: `bus=virtio`
- Network: `model=virtio`
- Display: `virtio` or `qxl`

### Disk I/O

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
  <source file='/mnt/vm/arch.qcow2'/>
  <target dev='vda' bus='virtio'/>
</disk>
```

### TRIM Support

In guest:
```bash
# Add discard mount option
# /etc/fstab
/dev/vda2 / ext4 defaults,discard 0 1

# Or run fstrim manually
sudo fstrim -av
```

## Cloning VMs

### Clone with virt-clone

```bash
# Clone VM (must be shut down)
virt-clone \
    --original arch \
    --name arch-clone \
    --auto-clone
```

### Manual Clone

```bash
# Copy disk
cp /mnt/vm/arch.qcow2 /mnt/vm/arch-clone.qcow2

# Dump and modify XML
virsh dumpxml arch > arch-clone.xml
# Edit: change name, UUID, MAC address, disk path
virsh define arch-clone.xml
```

### Reset Machine ID

After cloning, reset identifiers in guest:

```bash
# Remove machine-id
sudo rm /etc/machine-id
sudo systemd-machine-id-setup

# Generate new SSH host keys
sudo rm /etc/ssh/ssh_host_*
sudo ssh-keygen -A
```

## Templates

### Create Template

```bash
# Prepare VM (install, update, clean)
# In guest:
sudo pacman -Scc
sudo rm -rf /tmp/*
sudo rm /etc/machine-id

# Shutdown
virsh shutdown arch

# Mark as template (convention)
mv /mnt/vm/arch.qcow2 /mnt/vm/templates/arch-template.qcow2
```

### Create VM from Template

```bash
# Create backing file
qemu-img create -f qcow2 -b /mnt/vm/templates/arch-template.qcow2 \
    -F qcow2 /mnt/vm/arch-new.qcow2

# Import
virt-install --name arch-new --import \
    --disk /mnt/vm/arch-new.qcow2 \
    --memory 2048 --vcpus 2 \
    --os-variant archlinux
```

## Quick Reference

```bash
# Manage VMs
virsh list --all
virsh start arch
virsh shutdown arch
virsh console arch

# Guest tools (Arch)
pacman -S qemu-guest-agent spice-vdagent
systemctl enable --now qemu-guest-agent

# Guest tools (Debian/Kali)
apt install qemu-guest-agent spice-vdagent

# Clone
virt-clone --original arch --name arch-clone --auto-clone

# Connect
virt-viewer arch
```

## Related

- [03-CREATING-VMS](./03-CREATING-VMS.md) - Creation methods
- [06-NETWORKING](./06-NETWORKING.md) - Network options
- [08-PERFORMANCE](./08-PERFORMANCE.md) - Tuning
