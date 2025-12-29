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
2. Install virtiofs driver from virtio-win
3. Run: `net use Z: \\?\virtiofs\hostshare`

## 9p Filesystem (Alternative)

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

| Mode | Performance | Safety | Use Case |
|------|-------------|--------|----------|
| none | Best | Safe | Production |
| writeback | Good | Risky | Development |
| writethrough | OK | Safe | Fallback |

### Set Cache Mode

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' discard='unmap'/>
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

```bash
# After TRIM in guest
qemu-img convert -O qcow2 disk.qcow2 disk-trimmed.qcow2
mv disk-trimmed.qcow2 disk.qcow2
```

## Storage Performance

### Best Practices

1. **Use VirtIO** disk bus
2. **cache=none** for safety
3. **io=native** for direct I/O
4. **discard=unmap** for TRIM
5. Store on **SSD/NVMe**
6. Use **Btrfs subvolume** (COW disabled for qcow2)

### Disable Btrfs COW for VM Images

```bash
# For new directory
mkdir /mnt/vm-nocow
chattr +C /mnt/vm-nocow

# Check
lsattr -d /mnt/vm-nocow
```

### Optimal Disk Config

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
