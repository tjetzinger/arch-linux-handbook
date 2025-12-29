# 09 - Troubleshooting

Common issues and solutions for KVM/QEMU virtual machines.

## Quick Diagnostics

```bash
# Service status
systemctl status libvirtd

# VM status
virsh list --all

# Network status
virsh net-list --all

# Logs
journalctl -u libvirtd -f
```

## Service Issues

### libvirtd Won't Start

```bash
# Check status
systemctl status libvirtd

# View logs
journalctl -xeu libvirtd

# Common fixes:
# 1. Check permissions
ls -la /var/run/libvirt/

# 2. Check config syntax
libvirtd --config /etc/libvirt/libvirtd.conf --verbose

# 3. Restart
sudo systemctl restart libvirtd
```

### Permission Denied

**Symptoms:** Can't connect to libvirt, can't start VMs

```bash
# Check group membership
groups $USER
# Should include 'libvirt'

# Add to group
sudo usermod -aG libvirt $USER

# Re-login or
newgrp libvirt

# Check socket permissions
ls -la /var/run/libvirt/libvirt-sock
```

### Socket Not Available

```bash
# Enable socket
sudo systemctl enable --now libvirtd.socket

# Check socket status
systemctl status libvirtd.socket
```

## VM Won't Start

### Check Error Message

```bash
virsh start win11
# Note the error message

# More details
virsh start win11 --console
```

### Common Causes

**Missing disk image:**
```bash
# Verify disk exists
ls -la /mnt/vm/win11.qcow2

# Check VM config
virsh domblklist win11
```

**NVRAM missing (UEFI VMs):**
```bash
# Check NVRAM path
virsh dumpxml win11 | grep nvram

# Create from template
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd /mnt/vm/win11_VARS.fd
```

**Network not active:**
```bash
virsh net-start default
```

**Insufficient permissions:**
```bash
# Check file ownership
ls -la /mnt/vm/win11.qcow2

# Fix if needed
sudo chown libvirt-qemu:libvirt-qemu /mnt/vm/win11.qcow2
```

### KVM Not Available

```bash
# Check KVM module
lsmod | grep kvm

# Load if missing
sudo modprobe kvm
sudo modprobe kvm_intel  # or kvm_amd

# Check CPU support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should be > 0

# Check BIOS settings - VT-x must be enabled
```

## VM Performance Issues

### Slow Disk I/O

```bash
# Check disk bus
virsh dumpxml win11 | grep -A5 "<disk"
# Should show bus='virtio'

# Check cache mode
virsh dumpxml win11 | grep cache
# Recommended: cache='none'

# In guest - check TRIM
fstrim -av
```

**Fix: Change to VirtIO**
```bash
virsh edit win11
# Change bus='sata' to bus='virtio'
```

### High CPU Usage

```bash
# Check CPU mode
virsh dumpxml win11 | grep -A3 "<cpu"

# Should be host-passthrough
# Not 'qemu64' or 'custom'

# Check for CPU pinning issues
virsh vcpuinfo win11
```

### Memory Issues

```bash
# Check balloon driver
virsh dommemstat win11

# If memory shows 0, balloon driver not working
# Install guest agent in VM

# Check host memory
free -h
```

## Network Issues

### VM Has No Network

```bash
# 1. Check default network
virsh net-list --all
# Should show 'default' as active

# Start if needed
virsh net-start default

# 2. Check VM interface
virsh domiflist win11

# 3. Check DHCP lease
virsh net-dhcp-leases default

# 4. In VM, check interface
ip addr
ip route
```

### Can't Reach Internet from VM

```bash
# Check IP forwarding on host
cat /proc/sys/net/ipv4/ip_forward
# Should be 1

# Enable if needed
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -n -v
# Should show MASQUERADE for virbr0
```

### Network Is Slow

```bash
# Check network model
virsh dumpxml win11 | grep -A3 "<interface"
# Should show model type='virtio'

# Check vhost
virsh dumpxml win11 | grep driver
# Should show name='vhost'
```

## Display Issues

### Can't Connect to VM Display

```bash
# Check SPICE port
virsh domdisplay win11
# Returns: spice://localhost:5900

# Try virt-viewer
virt-viewer win11

# Check if SPICE is running
ss -tlnp | grep 5900
```

### Black Screen

```bash
# Check video config
virsh dumpxml win11 | grep -A5 "<video"

# Try different video model
virsh edit win11
# Change model type='qxl' or type='virtio'
```

### Resolution Issues

1. Install SPICE guest tools in VM
2. Resize virt-viewer window
3. Resolution should auto-adjust

For fixed resolution:
```xml
<video>
  <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1'>
    <resolution x='1920' y='1080'/>
  </model>
</video>
```

## Storage Issues

### Disk I/O Error

**Current win11 has an I/O error:**
```
I/O error: disk='vdb', path='/mnt/vm/win11.qcow2'
```

**Diagnose:**
```bash
# Check disk integrity
qemu-img check /mnt/vm/win11.qcow2

# Check host filesystem
dmesg | tail -50
# Look for Btrfs or NVMe errors

# Check disk space
df -h /mnt/vm/
```

**Fix:**
```bash
# If qcow2 corrupted, try repair
qemu-img check -r all /mnt/vm/win11.qcow2

# If Btrfs issues, run scrub
sudo btrfs scrub start /mnt/vm
```

### Disk Full

```bash
# Check host space
df -h

# Check qcow2 actual size
qemu-img info /mnt/vm/win11.qcow2

# Reclaim space (after TRIM in guest)
qemu-img convert -O qcow2 disk.qcow2 disk-new.qcow2
mv disk-new.qcow2 disk.qcow2
```

### Snapshot Issues

```bash
# List snapshots
virsh snapshot-list win11

# If stuck snapshot
virsh snapshot-delete win11 <name> --metadata

# Check backing chain
qemu-img info --backing-chain /mnt/vm/win11.qcow2
```

## Windows-Specific Issues

### Windows Won't Boot After Changes

```bash
# Reset UEFI NVRAM
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd /mnt/vm/win11_SECURE_VARS.fd
```

### Blue Screen During Install

- Use SATA instead of VirtIO initially
- Load VirtIO drivers during install
- Check memory isn't overcommitted

### TPM Errors

```bash
# Check swtpm
ps aux | grep swtpm

# Clear TPM state
rm -rf /mnt/vm/tpm/*

# Restart VM
virsh destroy win11
virsh start win11
```

### No Network After Install

1. Open Device Manager
2. Find unknown network device
3. Update driver from VirtIO ISO
4. Select `NetKVM\w11\amd64`

## Log Locations

```bash
# libvirt logs
/var/log/libvirt/qemu/<vm>.log

# View live
tail -f /var/log/libvirt/qemu/win11.log

# Journal
journalctl -u libvirtd
```

## QEMU Monitor Commands

```bash
# Enter monitor
virsh qemu-monitor-command win11 --hmp 'help'

# Useful commands
virsh qemu-monitor-command win11 --hmp 'info block'
virsh qemu-monitor-command win11 --hmp 'info network'
virsh qemu-monitor-command win11 --hmp 'info cpus'
virsh qemu-monitor-command win11 --hmp 'info status'
```

## Force Operations

### Force Stop VM

```bash
# Graceful shutdown
virsh shutdown win11

# Wait, then force
virsh destroy win11
```

### Force Remove VM

```bash
# Undefine (keeps disk)
virsh undefine win11

# Undefine with NVRAM
virsh undefine win11 --nvram

# Delete disk manually
rm /mnt/vm/win11.qcow2
```

### Reset Stuck VM

```bash
# Force reboot
virsh reset win11

# Or destroy and start
virsh destroy win11
virsh start win11
```

## Recovery

### Recover VM Config

```bash
# If VM was defined, config is in
ls /etc/libvirt/qemu/

# Re-define from backup
virsh define /backup/win11.xml
```

### Recover from Bad Edit

```bash
# libvirt keeps backups
ls /etc/libvirt/qemu/
# Look for .xml files

# Original configs may be in
/etc/libvirt/qemu/autostart/
```

### Mount VM Disk on Host

```bash
# Load NBD module
sudo modprobe nbd max_part=8

# Connect disk
sudo qemu-nbd --connect=/dev/nbd0 /mnt/vm/win11.qcow2

# View partitions
sudo fdisk -l /dev/nbd0

# Mount partition
sudo mount /dev/nbd0p2 /mnt/vm-disk

# When done
sudo umount /mnt/vm-disk
sudo qemu-nbd --disconnect /dev/nbd0
```

## Quick Reference

```bash
# Diagnostics
systemctl status libvirtd
virsh list --all
journalctl -u libvirtd -f

# Force operations
virsh destroy <vm>
virsh undefine <vm> --nvram

# Check disk
qemu-img check disk.qcow2
qemu-img info disk.qcow2

# Logs
tail -f /var/log/libvirt/qemu/<vm>.log

# QEMU monitor
virsh qemu-monitor-command <vm> --hmp 'info block'
```

## Related

- [02-LIBVIRT-SETUP](./02-LIBVIRT-SETUP.md) - Initial setup
- [07-STORAGE](./07-STORAGE.md) - Disk issues
- [08-PERFORMANCE](./08-PERFORMANCE.md) - Performance problems
