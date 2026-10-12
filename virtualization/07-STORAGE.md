# 07 - Storage

Disk images, snapshots, backups, and virtiofs shared folders.

## Storage Architecture

```
/mnt/vm/                        # Btrfs subvolume @vm
├── win11.qcow2                 # Windows 11 (40GB)
├── win11_SECURE_VARS.fd        # UEFI variables
├── kali-linux-*.qcow2          # Kali (33GB)
├── tpm/                        # TPM state
└── iso/                        # ISO images

/var/lib/libvirt/images/        # Default pool
└── arch-vm-minimal.qcow2       # Arch (69GB)

/var/lib/libvirt/qemu/nvram/    # NVRAM storage
└── arch_VARS.fd
```

## Storage Pools

### Current Pools

| Pool | Path | Purpose |
|------|------|---------|
| default | /var/lib/libvirt/images | System default |
| vm | /mnt/vm | Main VM storage |
| iso | /mnt/vm/iso | ISO images |
| nvram | /var/lib/libvirt/qemu/nvram | UEFI variables |

### Manage Pools

```bash
# List pools
virsh pool-list --all

# Pool info
virsh pool-info vm

# Refresh (detect new files)
virsh pool-refresh vm

# List volumes
virsh vol-list vm
```

### Create New Pool

```bash
# Define pool
virsh pool-define-as mypool dir --target /path/to/storage

# Build (creates directory)
virsh pool-build mypool

# Start and autostart
virsh pool-start mypool
virsh pool-autostart mypool
```

## Disk Image Formats

### qcow2 (Recommended)

- Copy-on-write
- Supports snapshots
- Supports compression
- Thin provisioning

```bash
# Create qcow2
qemu-img create -f qcow2 disk.qcow2 50G

# With preallocation (better performance)
qemu-img create -f qcow2 -o preallocation=metadata disk.qcow2 50G

# Full preallocation (best performance, uses full space)
qemu-img create -f qcow2 -o preallocation=full disk.qcow2 50G
```

### raw

- Best performance
- No snapshots
- Uses full space immediately

```bash
qemu-img create -f raw disk.raw 50G
```

## Disk Operations

### Check Disk Info

```bash
qemu-img info /mnt/vm/win11.qcow2
```

Output:
```
image: /mnt/vm/win11.qcow2
file format: qcow2
virtual size: 60 GiB
disk size: 40 GiB
```

### Resize Disk

```bash
# Shutdown VM first!
virsh shutdown win11

# Increase size
qemu-img resize /mnt/vm/win11.qcow2 +20G

# Then extend partition/filesystem in guest
```

### Convert Format

```bash
# qcow2 to raw
qemu-img convert -f qcow2 -O raw disk.qcow2 disk.raw

# raw to qcow2
qemu-img convert -f raw -O qcow2 disk.raw disk.qcow2

# Compress qcow2
qemu-img convert -c -f qcow2 -O qcow2 disk.qcow2 disk-compressed.qcow2
```

### Check/Repair

```bash
# Check for errors
qemu-img check disk.qcow2

# Repair
qemu-img check -r all disk.qcow2
```

## Snapshots

### Types of Snapshots

| Type | Description | Use Case |
|------|-------------|----------|
| Internal | Stored in qcow2 file | Simple, single file |
| External | Separate overlay file | Production, backups |

### Internal Snapshots

```bash
# Create snapshot (VM can be running)
virsh snapshot-create-as win11 snap1 "Before update"

# List snapshots
virsh snapshot-list win11

# Snapshot info
virsh snapshot-info win11 snap1

# Revert to snapshot
virsh snapshot-revert win11 snap1

# Delete snapshot
virsh snapshot-delete win11 snap1
```

### External Snapshots

```bash
# Create external snapshot (disk only)
virsh snapshot-create-as win11 snap1 \
    --disk-only \
    --atomic \
    --diskspec vdb,file=/mnt/vm/win11-snap1.qcow2

# After snapshot, win11.qcow2 becomes backing file
# win11-snap1.qcow2 is the active image
```

### Commit Changes (Merge)

```bash
# Merge snapshot back to base
virsh blockcommit win11 vdb --active --pivot
```

### Delete External Snapshot

```bash
# Blockcommit first, then delete overlay file
rm /mnt/vm/win11-snap1.qcow2
```

## Backups

### Simple File Copy

```bash
# Shutdown VM
virsh shutdown win11

# Copy disk
cp /mnt/vm/win11.qcow2 /backup/win11-$(date +%Y%m%d).qcow2

# Copy NVRAM (for UEFI VMs)
cp /mnt/vm/win11_SECURE_VARS.fd /backup/

# Export XML config
virsh dumpxml win11 > /backup/win11.xml
```

### Live Backup (External Snapshot)

```bash
# Create snapshot for consistent backup
virsh snapshot-create-as win11 backup-snap --disk-only --atomic

# Copy the original (now read-only) disk
cp /mnt/vm/win11.qcow2 /backup/

# Commit and delete snapshot
virsh blockcommit win11 vdb --active --pivot
```

### With Borg

```bash
# Backup VM directory
borg create /backup/vms::win11-{now} /mnt/vm/win11.qcow2 /mnt/vm/win11_SECURE_VARS.fd

# With compression
borg create --compression zstd /backup/vms::win11-{now} /mnt/vm/win11.qcow2
```

## virtiofs - Shared Folders

### Requirements

- QEMU 5.0+
- Linux 5.4+ kernel (host and guest)
- virtiofsd daemon

### Configure virtiofs

```xml
<!-- Add to VM XML -->
<memoryBacking>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>

<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs'/>
  <source dir='/home/tt/shared'/>
  <target dir='hostshare'/>
</filesystem>
```

### Mount in Linux Guest

```bash
# Manual mount
sudo mount -t virtiofs hostshare /mnt/shared

# Persistent (fstab)
echo "hostshare /mnt/shared virtiofs defaults 0 0" | sudo tee -a /etc/fstab
```

### Mount in Windows Guest

1. Install WinFsp: https://winfsp.dev/
2. Install the virtiofs driver and service from virtio-win
3. Set `VirtioFsSvc` to automatic and start it; the share appears as `Z:`

See [04-WINDOWS-VM - virtiofs](./04-WINDOWS-VM.md#virtiofs---shared-folders) for the live win11 setup.

## 9p Filesystem (Alternative)

Linux guests only: Windows has no 9p client, use virtiofs there.

### Configure 9p

```xml
<filesystem type='mount' accessmode='mapped'>
  <source dir='/home/tt/shared'/>
  <target dir='hostshare'/>
</filesystem>
```

### Mount in Guest

```bash
sudo mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/shared
```

## Disk Caching

### Cache Modes

On Btrfs, pick the cache mode by the image's COW state:

| Image | Cache mode | Why |
|-------|------------|-----|
| datacow (no `C`, has checksums) | `cache='writeback'` (QEMU default) | `none` causes false checksum errors on reads (see below). Host RAM caches reads. Guest flushes are honoured |
| nodatacow (`lsattr` shows `C`) | `cache='none' io='native'` | True direct I/O, fastest |
| any | `cache='writethrough'` | Safe fallback, slower writes |

**Never `cache='none'` on a datacow image.** With direct I/O, the guest can change a buffer while Btrfs checks or computes its checksum, so data and checksum no longer match. Kernel 6.14 fixed the write side (Btrfs falls back to buffered writes for files with checksums). Reads are still affected: on kernel 7.1.8, win11 with `cache='none'` logged 495 checksum errors in one day; with `writeback` only the one real bad block showed up.

**Trade-off of nodatacow:** no checksums, so Btrfs cannot detect corruption in the image. Each snapper snapshot of `@vm` also forces COW again for changed blocks. `win11.qcow2` stays datacow on purpose: checksums caught the corruption in the incident below, and the `vm` snapper config protects it.

Current images:

| Image | COW | Cache |
|-------|-----|-------|
| `/mnt/vm/win11.qcow2` | datacow | `writeback` |
| `/mnt/vm/kali-linux-*.qcow2` | datacow | default |
| `/var/lib/libvirt/images/arch-vm-minimal.qcow2` | nodatacow | default |

See [12-BTRFS-CORRUPTION-VM-INCIDENT](../system-recovery/12-BTRFS-CORRUPTION-VM-INCIDENT.md) for the incident.

### Set Cache Mode

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='writeback' discard='unmap'/>
  <source file='/mnt/vm/win11.qcow2'/>
  <target dev='vda' bus='virtio'/>
</disk>
```

## TRIM/Discard Support

### Enable in VM Config

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' discard='unmap'/>
  ...
</disk>
```

### In Guest

**Linux:**
```bash
# Mount with discard
mount -o discard /dev/vda1 /

# Or manual trim
fstrim -av
```

**Windows:**
- Automatic with virtio-win drivers
- Verify: `fsutil behavior query DisableDeleteNotify`

### Reclaim Space on Host

With `discard='unmap'`, QEMU frees the space by itself: a TRIM in the guest punches a hole in the qcow2 file. Seen on 2026-10-12: deleting `C:\Windows\MEMORY.DMP` in win11 plus a retrim removed the bad block from `win11.qcow2`.

```bash
# Check that the guest range is unallocated now
qemu-img map -U --output=json /mnt/vm/win11.qcow2 | head
du -h --apparent-size /mnt/vm/win11.qcow2; du -h /mnt/vm/win11.qcow2
```

`qemu-img convert` is only needed to compact or defragment the image, with the VM shut down. The copy is a new file in `/mnt/vm`, which has `chattr +C`, so it becomes **nodatacow** (no checksums) unless you remove the flag first:

```bash
touch /mnt/vm/disk-new.qcow2 && chattr -C /mnt/vm/disk-new.qcow2   # keep datacow
qemu-img convert -O qcow2 /mnt/vm/disk.qcow2 /mnt/vm/disk-new.qcow2
lsattr /mnt/vm/disk-new.qcow2   # no 'C' = datacow; else switch the VM to cache='none'
```

## Storage Performance

### Best Practices

1. **Use VirtIO** disk bus
2. **Cache mode by COW state**: `cache=writeback` for datacow images, `cache=none` + `io=native` for nodatacow images (see [Disk Caching](#disk-caching))
3. **discard=unmap** for TRIM
4. Store on **SSD/NVMe**
5. Use a **Btrfs subvolume** (`@vm`) with `chattr +C` on the directory for new images

### Disable Btrfs COW for VM Images

```bash
# Set on the directory: only NEW files inherit it (already set on /mnt/vm)
chattr +C /mnt/vm

# Check directory and images
lsattr -d /mnt/vm
lsattr /mnt/vm/*.qcow2
```

Existing images keep their COW state. A copy (`cp`, `qemu-img convert`) creates a new file, which inherits `+C`. After that, switch the VM to `cache='none' io='native'`.

### Optimal Disk Config (nodatacow image)

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
  <source file='/mnt/vm/disk.qcow2'/>
  <target dev='vda' bus='virtio'/>
</disk>
```

## Quick Reference

```bash
# Pool management
virsh pool-list --all
virsh pool-refresh vm
virsh vol-list vm

# Disk operations
qemu-img info disk.qcow2
qemu-img create -f qcow2 disk.qcow2 50G
qemu-img resize disk.qcow2 +20G
qemu-img convert -O qcow2 old.raw new.qcow2

# Snapshots
virsh snapshot-create-as vm snap1
virsh snapshot-list vm
virsh snapshot-revert vm snap1

# Backup
virsh dumpxml vm > vm.xml
cp disk.qcow2 backup/
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Storage layout
- [04-WINDOWS-VM](./04-WINDOWS-VM.md) - Windows virtiofs
- [08-PERFORMANCE](./08-PERFORMANCE.md) - I/O tuning
- [12-BTRFS-CORRUPTION-VM-INCIDENT](../system-recovery/12-BTRFS-CORRUPTION-VM-INCIDENT.md) - win11.qcow2 corruption and prevention
