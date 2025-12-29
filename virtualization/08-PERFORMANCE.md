# 08 - Performance

Optimization and tuning for KVM/QEMU virtual machines.

## Performance Checklist

| Setting | Recommended | Impact |
|---------|-------------|--------|
| Disk bus | VirtIO | High |
| Network model | VirtIO | High |
| CPU mode | host-passthrough | High |
| Disk cache | none | Medium |
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

```xml
<!-- Match physical topology for best cache performance -->
<cpu mode='host-passthrough'>
  <topology sockets='1' dies='1' clusters='1' cores='4' threads='2'/>
</cpu>
```

### CPU Pinning

Pin vCPUs to specific physical CPUs for consistent performance.

```xml
<vcpu placement='static'>6</vcpu>
<cputune>
  <!-- Pin vCPUs to P-cores (12-17 on i7-1370P) -->
  <vcpupin vcpu='0' cpuset='12'/>
  <vcpupin vcpu='1' cpuset='13'/>
  <vcpupin vcpu='2' cpuset='14'/>
  <vcpupin vcpu='3' cpuset='15'/>
  <vcpupin vcpu='4' cpuset='16'/>
  <vcpupin vcpu='5' cpuset='17'/>
  <!-- Pin emulator threads -->
  <emulatorpin cpuset='18-19'/>
</cputune>
```

### Find CPU Topology

```bash
# View CPU topology
lscpu -e

# Output shows CPU, Core, Socket info
# Pin VMs to appropriate cores
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

### Cache Modes

| Mode | Safety | Performance | Use Case |
|------|--------|-------------|----------|
| none | High | Best | Production |
| writeback | Low | Good | Testing |
| writethrough | High | OK | Legacy |
| directsync | Highest | Slow | Critical data |

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
    <vcpupin vcpu='0' cpuset='12'/>
    <vcpupin vcpu='1' cpuset='13'/>
    <vcpupin vcpu='2' cpuset='14'/>
    <vcpupin vcpu='3' cpuset='15'/>
    <emulatorpin cpuset='16-17'/>
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
