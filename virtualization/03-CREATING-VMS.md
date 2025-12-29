# 03 - Creating VMs

Methods for creating virtual machines with virt-manager and virt-install.

## virt-manager (GUI)

### Launch

```bash
virt-manager
```

### Create New VM

1. **File > New Virtual Machine**
2. **Choose installation method:**
   - Local install media (ISO)
   - Network install
   - Import existing disk
   - Manual install

3. **Select ISO or disk**
4. **Choose OS type** (auto-detected)
5. **Set Memory and CPUs**
6. **Configure storage**
7. **Review and customize before install**

### Recommended Settings

Before finishing, click "Customize configuration before install":

- **Firmware:** UEFI (for modern OSes)
- **Chipset:** Q35 (recommended)
- **Disk bus:** VirtIO (best performance)
- **Network:** VirtIO (best performance)

## virt-install (CLI)

### Basic Linux VM

```bash
virt-install \
    --name arch-test \
    --memory 2048 \
    --vcpus 2 \
    --disk size=20,format=qcow2,bus=virtio \
    --cdrom /mnt/vm/iso/archlinux-x86_64.iso \
    --network network=default,model=virtio \
    --graphics spice \
    --os-variant archlinux \
    --boot uefi
```

### Windows 11 VM

```bash
virt-install \
    --name win11 \
    --memory 8192 \
    --vcpus 4 \
    --disk size=60,format=qcow2,bus=virtio \
    --cdrom /mnt/vm/iso/Win11.iso \
    --disk /mnt/vm/iso/virtio-win.iso,device=cdrom \
    --network network=default,model=virtio \
    --graphics spice \
    --os-variant win11 \
    --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes \
    --features smm.state=on \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb
```

### Import Existing Disk

```bash
virt-install \
    --name imported-vm \
    --memory 2048 \
    --vcpus 2 \
    --disk /path/to/existing.qcow2,bus=virtio \
    --import \
    --network network=default,model=virtio \
    --graphics spice \
    --os-variant generic
```

### Minimal Headless Server

```bash
virt-install \
    --name server \
    --memory 1024 \
    --vcpus 1 \
    --disk size=10,format=qcow2 \
    --location http://mirror.archlinux.org/iso/latest/ \
    --network network=default \
    --graphics none \
    --console pty,target_type=serial \
    --extra-args 'console=ttyS0,115200n8 serial' \
    --os-variant archlinux
```

## OS Variants

### List Available Variants

```bash
# Search for OS variant
osinfo-query os | grep -i arch
osinfo-query os | grep -i windows
osinfo-query os | grep -i debian

# Common variants
archlinux
win11
win10
debian11
ubuntu22.04
fedora39
```

## Disk Options

### Create Disk Beforehand

```bash
# Create qcow2 disk
qemu-img create -f qcow2 /mnt/vm/myvm.qcow2 50G

# Create with preallocation (better performance)
qemu-img create -f qcow2 -o preallocation=metadata /mnt/vm/myvm.qcow2 50G
```

### Disk Parameters

```bash
--disk path=/mnt/vm/disk.qcow2,format=qcow2,bus=virtio,cache=none,discard=unmap

# Options:
# format: qcow2, raw
# bus: virtio (fast), sata, ide
# cache: none (recommended), writeback, writethrough
# discard: unmap (TRIM support)
```

## Network Options

### NAT (Default)

```bash
--network network=default,model=virtio
```

### Bridged Network

```bash
--network bridge=br0,model=virtio
```

### Multiple NICs

```bash
--network network=default,model=virtio \
--network network=isolated,model=virtio
```

### No Network

```bash
--network none
```

## Graphics Options

### SPICE (Recommended)

```bash
--graphics spice,listen=127.0.0.1
```

### VNC

```bash
--graphics vnc,listen=127.0.0.1,port=5900
```

### Headless (Console Only)

```bash
--graphics none \
--console pty,target_type=serial
```

## UEFI and Secure Boot

### UEFI Only

```bash
--boot uefi
```

### UEFI with Secure Boot

```bash
--boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes \
--features smm.state=on
```

### Legacy BIOS

```bash
--boot hd
# or omit --boot entirely
```

## TPM (Windows 11 Requirement)

### Add TPM 2.0

```bash
--tpm backend.type=emulator,backend.version=2.0,model=tpm-crb
```

## Complete Examples

### Arch Linux Desktop

```bash
virt-install \
    --name arch-desktop \
    --title "Arch Linux Desktop" \
    --memory 4096 \
    --vcpus 4 \
    --cpu host-passthrough \
    --disk path=/mnt/vm/arch-desktop.qcow2,size=40,format=qcow2,bus=virtio,cache=none \
    --cdrom /mnt/vm/iso/archlinux-x86_64.iso \
    --network network=default,model=virtio \
    --graphics spice,listen=none \
    --video qxl \
    --channel spicevmc \
    --sound ich9 \
    --boot uefi \
    --os-variant archlinux
```

### Kali Linux

```bash
virt-install \
    --name kali \
    --title "Kali Linux" \
    --memory 2048 \
    --vcpus 2 \
    --cpu host-passthrough \
    --disk path=/mnt/vm/kali.qcow2,size=40,format=qcow2,bus=virtio \
    --cdrom /mnt/vm/iso/kali-linux-installer-amd64.iso \
    --network network=default,model=virtio \
    --graphics spice \
    --os-variant debian11
```

### Windows 11 Complete

```bash
virt-install \
    --name win11 \
    --title "MS Windows 11" \
    --memory 16384 \
    --vcpus 6 \
    --cpu host-passthrough \
    --disk path=/mnt/vm/win11.qcow2,size=60,format=qcow2,bus=virtio,cache=none,discard=unmap \
    --cdrom /mnt/vm/iso/Win11.iso \
    --disk /mnt/vm/iso/virtio-win.iso,device=cdrom \
    --network network=default,model=virtio \
    --graphics spice,listen=none \
    --video qxl \
    --channel spicevmc \
    --sound ich9 \
    --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes \
    --features smm.state=on \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --os-variant win11
```

## Post-Creation

### Start VM

```bash
virsh start <vm-name>
```

### Connect to Display

```bash
virt-viewer <vm-name>
# or
remote-viewer spice://localhost:5900
```

### Console Access (Linux)

```bash
virsh console <vm-name>
# Exit with Ctrl+]
```

## XML Templates

### Export VM Configuration

```bash
virsh dumpxml win11 > win11.xml
```

### Create from XML

```bash
virsh define win11.xml
```

### Edit Running VM

```bash
virsh edit win11
```

## Quick Reference

```bash
# Create with virt-install
virt-install --name test --memory 2048 --vcpus 2 \
    --disk size=20 --cdrom /path/to/iso --os-variant generic

# List OS variants
osinfo-query os

# Create disk
qemu-img create -f qcow2 disk.qcow2 50G

# Import existing disk
virt-install --name vm --import --disk /path/to/disk.qcow2

# Define from XML
virsh define vm.xml
```

## Related

- [04-WINDOWS-VM](./04-WINDOWS-VM.md) - Windows-specific setup
- [05-LINUX-VMS](./05-LINUX-VMS.md) - Linux VM tips
- [07-STORAGE](./07-STORAGE.md) - Disk management
