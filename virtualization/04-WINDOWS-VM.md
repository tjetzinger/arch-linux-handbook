# 04 - Windows VM

Windows 11 setup with UEFI, Secure Boot, TPM, and performance optimizations.

## Current Configuration

| Setting | Value |
|---------|-------|
| Name | win11 |
| OS | Windows 11 |
| RAM | 16GB |
| vCPUs | 6 (pinned to cores 12-17) |
| Disk | 40GB qcow2 on /mnt/vm |
| Firmware | UEFI with Secure Boot |
| TPM | 2.0 (emulated via swtpm) |
| Display | SPICE with QXL |
| Shared folder | /home/tt via virtiofs |

## Windows 11 Requirements

Windows 11 requires:
- UEFI with Secure Boot
- TPM 2.0
- 4GB RAM minimum
- 64GB disk minimum

## Prerequisites

### Install Required Packages

```bash
# TPM emulator
sudo pacman -S swtpm

# UEFI firmware
sudo pacman -S edk2-ovmf

# VirtIO drivers ISO
# Download from: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/
# Or install: sudo pacman -S virtio-win (AUR)
```

### Download Windows 11 ISO

1. Go to [Microsoft Windows 11 Download](https://www.microsoft.com/software-download/windows11)
2. Download the ISO
3. Place in `/mnt/vm/iso/Win11.iso`

### Get VirtIO Drivers

```bash
# Download latest virtio-win.iso
# https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

# Or copy from existing location
ls /mnt/vm/iso/virtio-win.iso
```

## Installation

### Using virt-manager

1. **Create New VM**
   - Select "Local install media"
   - Browse to Win11.iso
   - OS: Microsoft Windows 11

2. **Resources**
   - Memory: 8192 MB minimum (16384 recommended)
   - CPUs: 4 minimum

3. **Storage**
   - Create disk: 60GB minimum
   - Bus: VirtIO (requires driver during install)

4. **Customize Before Install**

   **Firmware:**
   - Overview > Firmware: UEFI x86_64: /usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd

   **Add TPM:**
   - Add Hardware > TPM
   - Model: TIS
   - Backend: Emulated
   - Version: 2.0

   **Add VirtIO Driver CD:**
   - Add Hardware > Storage
   - Device type: CDROM
   - Select virtio-win.iso

5. **Begin Installation**

### Using virt-install

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

## During Installation

### Load VirtIO Storage Driver

When Windows Setup can't find the disk:

1. Click "Load driver"
2. Browse to VirtIO CD
3. Select `vioscsi\w11\amd64` or `viostor\w11\amd64`
4. Install driver
5. Disk should now appear

### Network Driver (Post-Install)

If network doesn't work after install:

1. Open Device Manager
2. Find unknown network device
3. Update driver > Browse > VirtIO CD
4. Select `NetKVM\w11\amd64`

## Post-Installation

### Install All VirtIO Drivers

1. Open VirtIO CD in Windows Explorer
2. Run `virtio-win-guest-tools.exe`
3. Install all drivers and QEMU Guest Agent

### Install SPICE Guest Tools

For better display and clipboard:

1. Download from: https://www.spice-space.org/download/windows/spice-guest-tools/
2. Or use: `spice-guest-tools-latest.exe` from virtio-win ISO
3. Enables:
   - Dynamic resolution
   - Clipboard sharing
   - Drag and drop

### Enable TRIM (SSD)

In Windows:
```powershell
# Verify TRIM is enabled
fsutil behavior query DisableDeleteNotify
# Should show: DisableDeleteNotify = 0
```

## virtiofs - Shared Folders

### Current Setup

The win11 VM shares `/home/tt` from the host.

### XML Configuration

```xml
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs'/>
  <binary path='/usr/lib/virtiofsd'/>
  <source dir='/home/tt'/>
  <target dir='x1-home'/>
</filesystem>
```

### Memory Backing Required

```xml
<memoryBacking>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>
```

### Mount in Windows

1. Install WinFsp: https://winfsp.dev/
2. Install virtiofs driver from virtio-win
3. The share appears as a network drive

Or manually:
```powershell
# In elevated PowerShell
net use Z: \\?\virtiofs\x1-home
```

### Add virtiofs via virt-manager

1. Add Hardware > Filesystem
2. Driver: virtiofs
3. Source path: /home/tt
4. Target path: x1-home

## CPU Pinning

### Current Configuration

```xml
<vcpu placement='static'>6</vcpu>
<cputune>
  <vcpupin vcpu='0' cpuset='12'/>
  <vcpupin vcpu='1' cpuset='13'/>
  <vcpupin vcpu='2' cpuset='14'/>
  <vcpupin vcpu='3' cpuset='15'/>
  <vcpupin vcpu='4' cpuset='16'/>
  <vcpupin vcpu='5' cpuset='17'/>
  <emulatorpin cpuset='18-19'/>
</cputune>
```

### Why Pin CPUs?

- Reduces context switching
- Better cache locality
- More consistent performance
- Reserve host CPUs (0-11) for other tasks

### View CPU Topology

```bash
lscpu -e
# Shows CPU topology for pinning decisions
```

## Hyper-V Enlightenments

### Current Configuration

```xml
<features>
  <hyperv mode='passthrough'>
    <!-- All Hyper-V features enabled -->
  </hyperv>
</features>
```

### Benefits

- Windows recognizes it's running on a hypervisor
- Enables optimized code paths
- Better timer handling
- Improved performance

## Display Configuration

### SPICE with QXL

```xml
<graphics type='spice' port='5900' autoport='yes' listen='127.0.0.1'>
  <listen type='address' address='127.0.0.1'/>
  <image compression='off'/>
</graphics>
<video>
  <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1'/>
</video>
```

### Connect to Display

```bash
virt-viewer win11
# or
remote-viewer spice://localhost:5900
```

### Resolution Changes

With SPICE guest tools installed:
- Resize virt-viewer window
- Resolution auto-adjusts

## USB Passthrough

### Redirect USB Device

In virt-viewer: Input > Select USB devices

### Add USB Controller (XML)

```xml
<controller type='usb' index='0' model='qemu-xhci' ports='15'/>
```

### Permanent USB Assignment

```xml
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <vendor id='0x1234'/>
    <product id='0x5678'/>
  </source>
</hostdev>
```

Find vendor/product IDs:
```bash
lsusb
```

## TPM Management

### TPM State Location

```
/mnt/vm/tpm/          # TPM state directory
/mnt/vm/swtpm-sock    # TPM socket
```

### Verify TPM in Windows

```powershell
# Open TPM Management
tpm.msc

# Or PowerShell
Get-Tpm
```

## Backup and Snapshots

### Backup VM

```bash
# Shutdown VM first
virsh shutdown win11

# Copy disk image
cp /mnt/vm/win11.qcow2 /backup/win11-$(date +%Y%m%d).qcow2

# Also backup NVRAM
cp /mnt/vm/win11_SECURE_VARS.fd /backup/
```

### Create Snapshot

```bash
# External snapshot (recommended)
virsh snapshot-create-as win11 snapshot1 --disk-only --atomic

# Revert (complex with external snapshots)
# See 07-STORAGE.md for details
```

## Performance Tips

1. **Use VirtIO** for disk and network
2. **Enable CPU pinning** for consistent performance
3. **Use cache=none** for disk (if host has good I/O)
4. **Enable hugepages** for large memory VMs
5. **Install guest tools** (SPICE, QEMU agent)
6. **Disable Windows features** you don't need

## Troubleshooting

### Windows Won't Boot

```bash
# Check Secure Boot NVRAM
ls -la /mnt/vm/win11_SECURE_VARS.fd

# Reset NVRAM if corrupted
virsh shutdown win11
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd /mnt/vm/win11_SECURE_VARS.fd
```

### TPM Errors

```bash
# Check swtpm process
ps aux | grep swtpm

# Restart VM to reinitialize TPM
virsh destroy win11
virsh start win11
```

### Blue Screen During Install

- Ensure VirtIO drivers are loaded
- Try SATA bus instead of VirtIO initially
- Check memory isn't overcommitted

### No Network

1. Verify virtio-net driver installed
2. Check network model is 'virtio'
3. Verify default network is active: `virsh net-list`

## Quick Reference

```bash
# Start/Stop
virsh start win11
virsh shutdown win11
virsh destroy win11  # Force stop

# Connect
virt-viewer win11

# Info
virsh dominfo win11
virsh domblklist win11

# Edit config
virsh edit win11
```

## Related

- [03-CREATING-VMS](./03-CREATING-VMS.md) - VM creation
- [07-STORAGE](./07-STORAGE.md) - Snapshots and backups
- [08-PERFORMANCE](./08-PERFORMANCE.md) - Tuning guide
