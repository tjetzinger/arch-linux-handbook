# 08 - Performance

Optimization and tuning for KVM/QEMU virtual machines.

## Performance Checklist

| Setting | Recommended | Impact |
|---------|-------------|--------|
| Disk bus | VirtIO | High |
| Network model | VirtIO | High |
| CPU mode | host-passthrough | High |
| Disk cache | writeback (datacow) / none (nodatacow), see [07-STORAGE](./07-STORAGE.md#disk-caching) | High |
| CPU pinning | Yes (for dedicated VMs) | Medium |
| Hugepages | Yes (for large RAM) | Medium |
| Multi-queue | Yes (for high I/O) | Medium |

## CPU Configuration

### CPU Mode

```xml
<!-- Best performance: pass through host CPU -->
<cpu mode='host-passthrough' check='none' migratable='on'/>

<!-- Good: host model with features -->
<cpu mode='host-model' check='partial'/>

<!-- Basic: emulated CPU -->
<cpu mode='custom' match='exact'>
  <model fallback='allow'>qemu64</model>
</cpu>
```

### CPU Topology

Always set `<topology>`. Without it, QEMU gives each vCPU its own socket (`sockets=N, cores=1`). Windows client editions use at most 2 sockets (Pro) or 1 (Home).

```xml
<!-- 1 socket, cores = vCPU count; threads='1' when pinned to one thread per core -->
<cpu mode='host-passthrough' check='none' migratable='on'>
  <topology sockets='1' dies='1' clusters='1' cores='6' threads='1'/>
</cpu>
```

### CPU Pinning

Pin vCPUs to specific physical CPUs for consistent performance.

**i7-1370P layout** (from `/sys/devices/cpu_core/cpus` and `/sys/devices/cpu_atom/cpus`):

| CPUs | Type | Cores |
|------|------|-------|
| 0-11 | P-cores, 2 threads each (siblings 0+1, 2+3, ...) | 6 |
| 12-19 | E-cores, 1 thread each | 8 |

Pin vCPUs to P-cores and the emulator threads to E-cores:

```xml
<vcpu placement='static'>6</vcpu>
<cputune>
  <!-- One thread per P-core -->
  <vcpupin vcpu='0' cpuset='0'/>
  <vcpupin vcpu='1' cpuset='2'/>
  <vcpupin vcpu='2' cpuset='4'/>
  <vcpupin vcpu='3' cpuset='6'/>
  <vcpupin vcpu='4' cpuset='8'/>
  <vcpupin vcpu='5' cpuset='10'/>
  <!-- Emulator threads on E-cores -->
  <emulatorpin cpuset='12-19'/>
</cputune>
```

This is the live win11 config, see [04-WINDOWS-VM](./04-WINDOWS-VM.md#cpu-pinning).

### Find CPU Topology

```bash
# View CPU topology
lscpu -e=CPU,CORE,SOCKET

# P-cores vs E-cores on hybrid Intel CPUs
cat /sys/devices/cpu_core/cpus   # P-cores
cat /sys/devices/cpu_atom/cpus   # E-cores
```

### CPU Governor

```bash
# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set performance mode (for VM host)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

## Memory Configuration

### Basic Memory

```xml
<memory unit='GiB'>16</memory>
<currentMemory unit='GiB'>16</currentMemory>
```

### Memory Ballooning

Dynamically adjust memory (requires guest driver):

```xml
<memballoon model='virtio'>
  <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
</memballoon>
```

### Hugepages

For VMs with 4GB+ RAM, hugepages reduce TLB misses.

**Enable hugepages on host:**

```bash
# Check current hugepages
cat /proc/meminfo | grep Huge

# Allocate hugepages (e.g., 8GB = 4096 x 2MB pages)
echo 4096 | sudo tee /proc/sys/vm/nr_hugepages

# Persistent
echo "vm.nr_hugepages = 4096" | sudo tee /etc/sysctl.d/99-hugepages.conf
```

**Use in VM:**

```xml
<memoryBacking>
  <hugepages/>
</memoryBacking>
```

### NUMA Configuration

For multi-socket systems:

```xml
<numatune>
  <memory mode='strict' nodeset='0'/>
</numatune>
```

## Disk I/O

### VirtIO Disk (Required)

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
  <source file='/mnt/vm/disk.qcow2'/>
  <target dev='vda' bus='virtio'/>
</disk>
```

This example is for a nodatacow image. New images in `/mnt/vm` are nodatacow, because the directory has `chattr +C`.

### Cache Modes

| Mode | Host page cache | Guest flushes | Use on Btrfs |
|------|-----------------|---------------|--------------|
| none | No (direct I/O) | Honoured | nodatacow images |
| writeback | Yes | Honoured | datacow images (QEMU default) |
| writethrough | Yes, every write synced | Not needed | Safe fallback, slow writes |
| directsync | No, every write synced | Not needed | Slowest |
| unsafe | Yes | Ignored | Throwaway VMs only |

See [07-STORAGE](./07-STORAGE.md#disk-caching) for how to pick by COW state.

### I/O Threads

Separate I/O from vCPU threads:

```xml
<iothreads>2</iothreads>
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native' iothread='1'/>
  ...
</disk>
```

### Multi-Queue Block

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' queues='4'/>
  ...
</disk>
```

### I/O Scheduler (Host)

```bash
# Check current scheduler
cat /sys/block/nvme0n1/queue/scheduler

# Use none/mq-deadline for NVMe
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler
```

## Network Performance

### VirtIO Network (Required)

```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
</interface>
```

### Multi-Queue Network

```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
  <driver name='vhost' queues='4'/>
</interface>
```

Set queues equal to vCPUs (up to max supported).

### Enable vhost

vhost offloads packet processing to kernel:

```xml
<driver name='vhost'/>
```

### TX/RX Queue Size

```xml
<driver name='vhost' queues='4' tx_queue_size='1024' rx_queue_size='1024'/>
```

## Display Performance

### virtio-gpu (Linux guests)

Best for Linux with 3D:

```xml
<video>
  <model type='virtio' heads='1' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>
```

### QXL (Windows/SPICE)

Good for Windows with SPICE:

```xml
<video>
  <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1'/>
</video>
```

### SPICE Optimizations

```xml
<graphics type='spice'>
  <image compression='off'/>
  <streaming mode='filter'/>
  <gl enable='no'/>
</graphics>
```

## Windows-Specific

### Hyper-V Enlightenments

```xml
<features>
  <hyperv mode='passthrough'>
    <relaxed state='on'/>
    <vapic state='on'/>
    <spinlocks state='on' retries='8191'/>
    <vpindex state='on'/>
    <synic state='on'/>
    <stimer state='on'/>
    <reset state='on'/>
    <frequencies state='on'/>
  </hyperv>
</features>
```

### Timer Configuration

```xml
<clock offset='localtime'>
  <timer name='rtc' tickpolicy='catchup'/>
  <timer name='pit' tickpolicy='delay'/>
  <timer name='hpet' present='no'/>
  <timer name='hypervclock' present='yes'/>
</clock>
```

## Benchmarking

### Disk I/O

```bash
# In guest
# Sequential write
dd if=/dev/zero of=test bs=1M count=1000 conv=fdatasync

# Random I/O (install fio)
fio --name=random-rw --ioengine=libaio --direct=1 --bs=4k \
    --size=1G --numjobs=4 --rw=randrw --group_reporting
```

### Network

```bash
# Install iperf3 on host and guest
# On host
iperf3 -s

# In guest
iperf3 -c 192.168.122.1
```

### CPU

```bash
# In guest
# Install sysbench
sysbench cpu --threads=4 run
```

## Monitoring

### Host Resource Usage

```bash
# vCPU usage
virsh cpu-stats win11

# Memory stats (requires balloon driver)
virsh dommemstat win11

# Block I/O
virsh domblkstat win11 vda

# Network I/O
virsh domifstat win11 vnet0
```

### virt-top

```bash
# Install virt-top
sudo pacman -S virt-top

# Run
virt-top
```

### QEMU Monitor

```bash
# Access QEMU monitor
virsh qemu-monitor-command win11 --hmp 'info block'
virsh qemu-monitor-command win11 --hmp 'info network'
```

## Complete Optimized Config

### High-Performance VM Example

```xml
<domain type='kvm'>
  <name>optimized-vm</name>
  <memory unit='GiB'>8</memory>
  <vcpu placement='static'>4</vcpu>

  <cpu mode='host-passthrough'>
    <topology sockets='1' cores='4' threads='1'/>
  </cpu>

  <cputune>
    <vcpupin vcpu='0' cpuset='0'/>
    <vcpupin vcpu='1' cpuset='2'/>
    <vcpupin vcpu='2' cpuset='4'/>
    <vcpupin vcpu='3' cpuset='6'/>
    <emulatorpin cpuset='12-19'/>
  </cputune>

  <memoryBacking>
    <hugepages/>
  </memoryBacking>

  <iothreads>2</iothreads>

  <os>
    <type arch='x86_64' machine='pc-q35-9.2'>hvm</type>
    <boot dev='hd'/>
  </os>

  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none' io='native' iothread='1'/>
      <source file='/mnt/vm/disk.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>

    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
      <driver name='vhost' queues='4'/>
    </interface>

    <video>
      <model type='virtio' heads='1'>
        <acceleration accel3d='yes'/>
      </model>
    </video>
  </devices>
</domain>
```

## Quick Reference

```bash
# Monitor VMs
virt-top
virsh cpu-stats <vm>
virsh dommemstat <vm>

# Check CPU governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Allocate hugepages
echo 4096 | sudo tee /proc/sys/vm/nr_hugepages

# I/O scheduler
cat /sys/block/nvme0n1/queue/scheduler
```

## Related

- [04-WINDOWS-VM](./04-WINDOWS-VM.md) - Windows optimizations
- [07-STORAGE](./07-STORAGE.md) - Disk tuning
- [09-TROUBLESHOOTING](./09-TROUBLESHOOTING.md) - Performance issues
