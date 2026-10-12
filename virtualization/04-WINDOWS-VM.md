# 04 - Windows VM

Windows 11 setup with UEFI, Secure Boot, TPM, and performance optimizations.

## Current Configuration

| Setting | Value |
|---------|-------|
| Name | win11 |
| OS | Windows 11 |
| RAM | 16GB |
| vCPUs | 6 (1 socket, 6 cores; pinned to one thread per P-core: CPUs 0,2,4,6,8,10) |
| Disk | 40GB qcow2 on /mnt/vm |
| Firmware | UEFI with Secure Boot |
| TPM | 2.0 (emulated via swtpm) |
| Nested virtualization | on, with `cet-ss`, `cet-ibt`, `vmx-apicv-register`, `vmx-apicv-vid` disabled so VBS / Memory Integrity boot. See [Boot Loop After a Host Update](#boot-loop-after-a-host-update-vbs--nested-virtualization) |
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
    --disk path=/mnt/vm/win11.qcow2,size=60,format=qcow2,bus=virtio,cache=none,io=native,discard=unmap \
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

libvirt finds `/usr/lib/virtiofsd` (package `virtiofsd`) on its own, so no `<binary>` line is needed.

### Mount in Windows

1. Install WinFsp: https://winfsp.dev/
2. Install the virtiofs driver and service from the virtio-win ISO
3. Set the `VirtIO-FS Service` to start automatically. It is installed as **manual**, so the share does not appear until it is started:

```powershell
# Elevated PowerShell
Set-Service VirtioFsSvc -StartupType Automatic
Start-Service VirtioFsSvc
Get-PSDrive Z          # Z:\  x1-home
```

The service mounts the share as the first free drive letter from `Z:` down, labelled with the target tag (`x1-home`).

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
  <vcpupin vcpu='0' cpuset='0'/>
  <vcpupin vcpu='1' cpuset='2'/>
  <vcpupin vcpu='2' cpuset='4'/>
  <vcpupin vcpu='3' cpuset='6'/>
  <vcpupin vcpu='4' cpuset='8'/>
  <vcpupin vcpu='5' cpuset='10'/>
  <emulatorpin cpuset='12-19'/>
</cputune>
<cpu mode='host-passthrough' check='none' migratable='on'>
  <topology sockets='1' dies='1' clusters='1' cores='6' threads='1'/>
  <feature policy='disable' name='cet-ss'/>
  <feature policy='disable' name='cet-ibt'/>
  <feature policy='disable' name='vmx-apicv-register'/>
  <feature policy='disable' name='vmx-apicv-vid'/>
</cpu>
```

- **vCPUs:** first thread of each of the 6 P-cores (CPUs 0,2,4,6,8,10). The sibling threads (1,3,5,...) stay free for the host.
- **Emulator threads:** on the E-cores (12-19), away from the vCPUs.
- **Topology:** 1 socket with 6 cores. Without `<topology>`, QEMU starts `-smp 6,sockets=6,cores=1`, and Windows 11 uses only 2 sockets (Pro) or 1 (Home), so most vCPUs sit idle. Check in the guest: Task Manager > Performance > CPU shows "Sockets: 1, Cores: 6".

- **Four CPU features off:** CET (`cet-ss`, `cet-ibt`) and nested APICv (`vmx-apicv-register`, `vmx-apicv-vid`). Required since kernel 7.2 for Windows with VBS, see [Boot Loop After a Host Update](#boot-loop-after-a-host-update-vbs--nested-virtualization).

See [08-PERFORMANCE](./08-PERFORMANCE.md#cpu-pinning) for the P-core/E-core map of this CPU.

### Why Pin CPUs?

- Reduces context switching
- Better cache locality
- More consistent performance
- Keeps the vCPUs on P-cores, so the host scheduler cannot move them to slower E-cores

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

## Boot Loop After a Host Update (VBS + Nested Virtualization)

**Incident 2026-10-11:** win11 had booted fine on 2026-08-14. After host updates (kernel 7.1 → 7.2.9, QEMU 11.1.0 → 11.1.2, `edk2-ovmf` 202605 → 202608, `swtpm` 0.10.1 → 0.10.2) every normal boot ended in "Ihr Gerät ist auf ein Problem gestoßen und konnte nicht repariert werden" (Automatic Repair). Safe Mode worked.

**Cause:** Memory Integrity (HVCI) is on in the guest (`HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity` → `Enabled = 1`). HVCI makes Windows start its own hypervisor through nested virtualization (`vmx` passed through by `host-passthrough`). On the updated host that start reset the VM about 6 seconds after Windows Boot Manager, with no blue screen, no dump and no event log entry. Safe Mode does not start the hypervisor, so it worked.

What changed on the host: since kernel 7.2, KVM offers MBEC (mode-based execute control, used by HVCI) to nested guests (`virsh domcapabilities` lists `vmx-mbec`; kernel 7.1.8 in August did not). QEMU passes CET (`cet-ss`, `cet-ibt`) to guests by default since 11.0. MBEC together with CET and nested APICv breaks Windows' VBS hypervisor on Intel:
- KVM mailing list report, same symptoms ("hangs during early boot" or "ends up in Windows Recovery Mode"), fixed with `-cet-ss,-cet-ibt`: https://lists.openwall.net/linux-kernel/2026/05/11/993
- Proxmox disables CET for Windows 11 guests by default: https://lore.proxmox.com/all/20260515155810.229819-1-f.ebner@proxmox.com/
- Proxmox disables nested APICv for Windows 11 guests (freezes at 100% CPU with VBS + MBEC): https://lore.proxmox.com/pve-devel/20260709134211.199744-3-f.ebner@proxmox.com/
- Kernel fix in progress, "KVM: nVMX: fix nested APICv emulation for windows guests" (2026-10-09): https://lkml.rescloud.iu.edu/2610.1/04485.html

**Why it looked like a repair loop:** after the first failed boots, Windows records them in `C:\Windows\bootstat.dat` and sends every later boot straight to Automatic Repair, even when the cause is gone. Each test must start with a reset boot status, or it proves nothing.

**Fix (live since 2026-10-11):** keep `vmx` and `host-passthrough`, switch off four features (same as the Proxmox defaults):

```xml
<cpu mode='host-passthrough' check='none' migratable='on'>
  <feature policy='disable' name='cet-ss'/>
  <feature policy='disable' name='cet-ibt'/>
  <feature policy='disable' name='vmx-apicv-register'/>
  <feature policy='disable' name='vmx-apicv-vid'/>
</cpu>
```

Check inside Windows that VBS and Memory Integrity run:

```powershell
Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard |
  Select VirtualizationBasedSecurityStatus, SecurityServicesRunning
# 2 / {2} = VBS running, HVCI running
```

Fallback if a future host update breaks it again: hide nested virtualization with `<feature policy='disable' name='vmx'/>`. Windows then boots without its hypervisor, but Memory Integrity, WSL2, Windows Sandbox and Hyper-V do not work. HVCI is not locked in UEFI (no `Locked` value), so Windows accepts that without complaint.

When newer kernels carry the nested APICv fix, the two `vmx-apicv-*` lines may become unnecessary. Test that with a `vm` snapshot first.

**Reset the boot status** (VM off, from the host). Back up the image or take a `vm` snapshot first:

```bash
sudo modprobe nbd max_part=8
sudo qemu-nbd -f qcow2 --connect=/dev/nbd0 /mnt/vm/win11.qcow2
sudo mkdir -p /mnt/win11c && sudo mount -t ntfs-3g /dev/nbd0p3 /mnt/win11c
sudo mv /mnt/win11c/Windows/bootstat.dat /mnt/win11c/Windows/bootstat.dat.old
sudo umount /mnt/win11c && sudo qemu-nbd --disconnect /dev/nbd0
```

Alternative from Safe Mode, no host write: `bcdedit /set {current} bootstatuspolicy ignoreallfailures`.

**Diagnostics that helped:**
- `virsh screenshot win11 f.png` once per second shows a reset loop as firmware text → black → 640×480 → firmware text.
- `virsh domstats win11 --block` with almost no writes means no crash dump was written.
- Read guest files and registry hives read-only from the host: `qemu-storage-daemon` with a FUSE export, then `ntfscat` / `ntfsls`, and `regipy` for the hives.
- Tests that did **not** help (they ran before the boot status was reset, so they proved little): CPU topology, fresh UEFI variables, sound/QXL/virtio-net swapped, `hyperv` enlightenments removed (hangs earlier).
- `virsh domcapabilities | grep vmx-mbec` shows whether the host offers MBEC to nested guests.

## Display Configuration

### SPICE with QXL

```xml
<graphics type='spice' port='5900' autoport='yes' listen='127.0.0.1'>
  <listen type='address' address='127.0.0.1'/>
  <image compression='off'/>
</graphics>
<video>
  <model type='qxl' ram='131072' vram='65536' vgamem='65536' heads='1' primary='yes'/>
</video>
```

`vgamem` limits the largest resolution: width × height × 4 bytes must fit. The host desktop uses fractional scaling, so virt-manager asks for the window size in physical pixels (about 3042×1682 for a full-screen window, ≈ 20.5 MB). With the old `vgamem='16384'` (16 MiB) Windows rejected that mode and stayed at 1920×1440 with black bars; the SPICE agent log showed `failed SetDisplayConfig with 0x64a`. `65536` (64 MiB) covers 4K. After the change, set Windows display scaling to about 150–175%.

### Connect to Display

```bash
virt-viewer win11
# or
remote-viewer spice://localhost:5900
```

### Resolution Changes

With SPICE guest tools installed (`vdagent` running) and auto-resize enabled in virt-manager for the VM:
- Resize the viewer window
- Resolution auto-adjusts

If it does not, check the agent log in the guest: `Get-Content C:\Windows\Temp\vdagent.log -Tail 20` (look for `SetDisplayConfig`).

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
3. **Match the cache mode to the image**: `cache=none` for nodatacow images, `cache=writeback` for datacow images. The current `win11.qcow2` is datacow and runs `writeback` (see [07-STORAGE](./07-STORAGE.md#disk-caching))
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
