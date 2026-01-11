# 10 - Performance Tuning

System performance optimizations for desktop responsiveness on ThinkPad X1 Carbon Gen 11 (62GB RAM, Intel i7-1370P).

## Overview

| Component | Purpose | Status |
|-----------|---------|--------|
| linux-cachyos | CachyOS optimized kernel | Active |
| scx_lavd | sched-ext scheduler | Running (autopower) |
| ananicy-cpp | Process priority management | Running |
| irqbalance | IRQ distribution across CPUs | Running |
| earlyoom | OOM prevention daemon | Running |
| preload | Adaptive readahead daemon | Running |
| sysctl tuning | VM and filesystem parameters | Applied |
| profile-sync-daemon | Browser profiles in RAM | Running (user) |

---

## CachyOS Kernel

High-performance kernel with AutoFDO profiling, LTO, and sched-ext support.

### Features

| Feature | Benefit |
|---------|---------|
| AutoFDO + Propeller | Profile-guided optimization (5-10% perf gain) |
| Thin LTO | Link-time optimization |
| 1000Hz tick rate | Lower latency |
| EEVDF scheduler | Modern base scheduler |
| sched-ext support | BPF-based userspace schedulers |
| x86-64-v3 | Architecture-specific optimizations |

### Current Kernel

```bash
# Check kernel
uname -r
# 6.18.3-2-cachyos

# Kernel info
pacman -Qi linux-cachyos
```

### Available Variants

| Kernel | Scheduler | Use Case |
|--------|-----------|----------|
| `linux-cachyos` | EEVDF + AutoFDO | **Default** - best overall |
| `linux-cachyos-bore` | BORE | Interactive/gaming |
| `linux-cachyos-lts` | BORE | Long-term stability |
| `linux-cachyos-hardened` | BORE | Security-focused |

---

## sched-ext Schedulers

BPF-based schedulers that run in userspace, allowing dynamic scheduler changes without rebooting.

### Available Schedulers

| Scheduler | Best For | Power Efficiency |
|-----------|----------|------------------|
| **scx_lavd** | Laptops, hybrid CPUs | ⭐⭐⭐⭐ Best (core compaction) |
| scx_bpfland | Desktop, general use | ⭐⭐⭐ Good |
| scx_flash | Fairness, consistency | ⭐⭐⭐ Good |
| scx_rusty | Tunable, server | ⭐⭐⭐ Good |
| scx_cosmos | General-purpose | ⭐⭐⭐ Good |

### Why scx_lavd for Intel Hybrid (i7-1370P)

- **Core Compaction** - When CPU < 50%, P-cores active, E-cores in deep sleep
- **Hybrid-Aware** - Understands P-core vs E-core performance differences
- **Autopower** - Automatically adjusts based on system EPP
- **Latency-Critical** - Prioritizes interactive tasks on P-cores

### Configuration

**File:** `/etc/scx_loader.toml`

```toml
default_sched = "scx_lavd"
default_mode = "Auto"

[scheds.scx_lavd]
auto_mode = ["--autopower"]
```

### Management Commands

```bash
# Check current scheduler
scxctl get

# Switch scheduler
scxctl switch --sched lavd --mode powersave
scxctl switch --sched bpfland --mode gaming

# Switch with custom args
scxctl switch --sched lavd --args="--autopower"

# Stop sched-ext (use kernel default)
scxctl stop

# Restart service
systemctl restart scx_loader.service
```

### Scheduler Modes

| Mode | Flag | Use Case |
|------|------|----------|
| Auto | default | Balanced, auto-adjusts |
| Gaming | `--performance` | Maximum performance |
| Powersave | `--powersave` | Battery life |
| Low Latency | varies | Audio production |

### Service

```bash
# Status
systemctl status scx_loader.service

# Logs
journalctl -u scx_loader.service -f

# Enable at boot
systemctl enable scx_loader.service
```

---

## linux-zen Kernel

Alternative optimized kernel for desktop responsiveness (fallback option).

### Features

| Feature | Benefit |
|---------|---------|
| 1000Hz tick rate | Lower latency vs 300Hz default |
| Preemptive scheduling | Better responsiveness under load |
| BFQ I/O scheduler | Optimized for interactive workloads |
| MuQSS/BORE patches | Improved CPU scheduling |
| Optimized defaults | Desktop-focused tuning |

### Boot Entry

**File:** `/boot/loader/entries/arch-zen.conf`

Select "Arch Linux (Zen)" from the boot menu to use the zen kernel.

### Configuration

**Initramfs config:** `/etc/mkinitcpio-zen.conf` (no nvidia modules - use mainline kernel for eGPU)

```bash
# Check current kernel
uname -r

# Regenerate initramfs
sudo mkinitcpio -p linux-zen

# Available kernels
ls /boot/vmlinuz-*
```

### When to Use

| Kernel | Use Case |
|--------|----------|
| linux-cachyos | **Default** - best performance |
| linux-zen | Alternative, no sched-ext |
| linux-lts | Stability, fallback |

---

## earlyoom

Daemon that prevents system freeze under memory pressure by killing memory hogs before the kernel OOM killer triggers.

### Why earlyoom?

Without earlyoom, low memory can cause:
- System becomes unresponsive for minutes
- Kernel OOM killer may kill wrong processes
- Desktop becomes unusable before swap kicks in

### Service

```bash
# Status
systemctl status earlyoom

# Logs
journalctl -u earlyoom -f
```

### Default Thresholds

| Action | Memory Available | Swap Free |
|--------|-----------------|-----------|
| SIGTERM | ≤ 10% | ≤ 10% |
| SIGKILL | ≤ 5% | ≤ 5% |

### Configuration

**File:** `/etc/default/earlyoom`

```bash
# Custom thresholds (optional)
EARLYOOM_ARGS="-m 5 -s 5 --avoid '(^|/)(init|systemd|sshd|Xorg)$'"
```

### Protected Processes

By default, earlyoom avoids killing:
- init, systemd
- Xorg, sshd

---

## preload

Adaptive readahead daemon that prefetches frequently used applications into RAM for faster startup.

### How It Works

1. Monitors application usage patterns
2. Learns which files are accessed together
3. Prefetches files into page cache during idle time
4. Applications start faster on subsequent launches

### Service

```bash
# Status
systemctl status preload

# Logs (sparse - only logs on state saves)
journalctl -u preload
```

### Configuration

**File:** `/etc/preload.conf`

Key settings:
```ini
# How often to save state (seconds)
cycle = 20

# Memory usage limits
memtotal = -10%     # Leave 10% RAM free
memfree = 50%       # Start prefetching when 50% free
```

### State File

**Location:** `/var/lib/preload/preload.state`

Stores learned application patterns. Deleted on package removal.

---

## ananicy-cpp

Auto-nice daemon that automatically adjusts process priorities for better desktop responsiveness.

### How It Works

- Monitors running processes
- Applies nice/ionice/oom_score based on predefined rules
- Prioritizes desktop apps (browsers, editors) over background tasks (builds, indexers)

### Service

```bash
# Status
systemctl status ananicy-cpp

# Logs
journalctl -u ananicy-cpp -f
```

### Configuration

**Rules directory:** `/etc/ananicy.d/`

```
/etc/ananicy.d/
├── 00-default/           # Default rules
├── 00-cgroups.cgroups    # Cgroup definitions
├── 00-types.types        # Process type definitions
└── *.rules               # Custom rules
```

### Default Types

| Type | Nice | IONice | Purpose |
|------|------|--------|---------|
| `Game` | -5 | best-effort | Gaming processes |
| `Player-Audio` | -8 | realtime | Audio players |
| `Browser` | -3 | best-effort | Web browsers |
| `BG_CPUIO` | 19 | idle | Background tasks |

### Custom Rules Example

**File:** `/etc/ananicy.d/custom.rules`

```ini
# Prioritize specific apps
{ "name": "code", "type": "Document-Editor" }
{ "name": "ollama", "type": "BG_CPUIO" }
```

---

## irqbalance

Distributes hardware interrupts across multiple CPUs for better performance.

### Why It Matters

Without irqbalance, all hardware interrupts may be handled by CPU 0, causing:
- CPU 0 bottleneck
- Higher latency for I/O operations
- Uneven CPU utilization

### Service

```bash
# Status
systemctl status irqbalance

# View current IRQ distribution
cat /proc/interrupts | head -20
```

### Configuration

**File:** `/etc/irqbalance.conf` (optional)

Default configuration works well for most systems.

---

## Sysctl Performance Tuning

Kernel parameters optimized for desktop usage with high RAM.

### Configuration

**File:** `/etc/sysctl.d/99-performance.conf`

```bash
# Performance tuning for desktop with high RAM (62GB)

# Reduce swappiness - prefer RAM over swap (default: 60)
vm.swappiness = 10

# Lower VFS cache pressure - keep more inodes/dentries cached (default: 100)
vm.vfs_cache_pressure = 50

# Dirty page settings - flush writes more frequently in smaller chunks
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Increase inotify limits for IDEs and file watchers
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
```

### Parameter Explanation

| Parameter | Default | Set | Effect |
|-----------|---------|-----|--------|
| `vm.swappiness` | 60 | 10 | Strongly prefer RAM over swap |
| `vm.vfs_cache_pressure` | 100 | 50 | Keep more directory/inode caches |
| `vm.dirty_ratio` | 40 | 10 | Flush dirty pages sooner (% of RAM) |
| `vm.dirty_background_ratio` | 10 | 5 | Background writeback threshold |
| `fs.inotify.max_user_watches` | 8192 | 524288 | Support large projects in IDEs |

### Why These Values?

**Swappiness = 10:**
With 62GB RAM, swapping should be a last resort. Lower values keep more data in RAM.

**VFS cache pressure = 50:**
Reduces cache reclaim pressure. Keeps file metadata cached longer, improving file access speed.

**Dirty ratios:**
Instead of buffering up to 25GB (40% of 62GB) of dirty data before flushing:
- `dirty_ratio=10` limits dirty pages to ~6GB max
- Writes happen more frequently but in smaller chunks
- Reduces lag spikes during large writes
- Better for SSD wear leveling

**Inotify limits:**
IDEs like VS Code, IntelliJ need high limits for file watching in large projects.

### Apply Without Reboot

```bash
sudo sysctl --system
```

### Verify Settings

```bash
sysctl vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio vm.dirty_background_ratio
```

---

## Profile-Sync-Daemon

Browser profiles running from RAM. See [applications/02-BROWSERS.md](../applications/02-BROWSERS.md#profile-sync-daemon-ram-profiles) for details.

```bash
# Status
psd p

# Service
systemctl --user status psd
```

---

## SSD Optimization

Already configured for optimal SSD performance.

### fstrim Timer

```bash
# Status
systemctl status fstrim.timer

# Manual trim
sudo fstrim -av
```

### I/O Scheduler

```bash
cat /sys/block/nvme0n1/queue/scheduler
# [none] mq-deadline kyber bfq
```

`none` is optimal for NVMe SSDs (no scheduling needed for parallel access).

### Mount Options

Btrfs mounted with optimal SSD options:
- `ssd` - SSD-specific optimizations
- `discard=async` - Asynchronous TRIM
- `compress=zstd` - Transparent compression

---

## Memory Usage

### Current Status

```bash
# Memory overview
free -h

# Detailed memory info
cat /proc/meminfo | grep -E "^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)"

# Top memory consumers
ps aux --sort=-%mem | head -10
```

### Swap Configuration

| Parameter | Value |
|-----------|-------|
| Swap file | `/swap/swapfile` |
| Size | 72GB |
| Swappiness | 10 |

**Note:** 72GB swap is larger than needed for 62GB RAM. 16GB would suffice for hibernate + minimal swap usage.

---

## Verification Commands

```bash
# All services
systemctl is-active ananicy-cpp irqbalance earlyoom preload tlp

# Current kernel
uname -r

# Sysctl values
sysctl vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio

# IRQ distribution
cat /proc/interrupts | head -5

# Process priorities (ananicy)
ps -eo pid,ni,comm --sort=-ni | head -20

# Memory status (earlyoom)
journalctl -u earlyoom --since "1 hour ago" | tail -5

# Browser RAM usage (psd)
psd p
```

---

## Quick Reference

```bash
# Service status
systemctl status ananicy-cpp irqbalance earlyoom preload

# Boot into zen kernel
# Select "Arch Linux (Zen)" from boot menu

# View ananicy rules
ls /etc/ananicy.d/

# Current sysctl values
sysctl -a | grep -E "swappiness|vfs_cache|dirty"

# Memory pressure
cat /proc/pressure/memory

# I/O pressure
cat /proc/pressure/io

# Preload state
ls -la /var/lib/preload/
```

---

## Shutdown Optimization

Reduce shutdown time by lowering the default service stop timeout.

### The Problem

Default systemd timeout is **90 seconds** per service. Systems with many services (Docker, libvirt, user services) may wait unnecessarily long during shutdown if a service doesn't stop cleanly.

### Services That Can Delay Shutdown

| Service | Default Timeout | Impact |
|---------|-----------------|--------|
| docker.service | 90s | Container cleanup |
| containerd.service | 90s | Runtime cleanup |
| libvirtd.service | 90s | VM cleanup |
| NetworkManager.service | 90s | Connection teardown |
| User session (user@1000) | 90s | User service cleanup |

### Solution: Reduce Default Timeout

**File:** `/etc/systemd/system.conf.d/10-timeout.conf`

```ini
[Manager]
DefaultTimeoutStopSec=15s
```

### Apply

```bash
# Create override
sudo mkdir -p /etc/systemd/system.conf.d/
sudo tee /etc/systemd/system.conf.d/10-timeout.conf << 'EOF'
[Manager]
DefaultTimeoutStopSec=15s
EOF

# Reload systemd
sudo systemctl daemon-reexec

# Verify
systemctl show --property=DefaultTimeoutStopUSec
# Output: DefaultTimeoutStopUSec=15s
```

### Analysis Commands

```bash
# Check last shutdown sequence
journalctl -b -1 -o short-monotonic | grep -iE "stopping|stopped" | tail -40

# Find slow-stopping services
journalctl -b -1 | grep -iE "timeout|killing|sigterm|sigkill"

# Check service timeout
systemctl show docker.service | grep TimeoutStopUSec

# View shutdown dependencies
systemctl list-dependencies shutdown.target --reverse
```

### Per-Service Override

For specific services that need more time:

```bash
# Create override for docker
sudo systemctl edit docker.service
```

```ini
[Service]
TimeoutStopSec=30s
```

### Fresh Arch Comparison

| Factor | Desktop System | Fresh Arch |
|--------|----------------|------------|
| Running services | 30+ system, 17+ user | ~15 total |
| Docker/containers | Yes | No |
| libvirt/VMs | Yes | No |
| Plymouth | Yes | No |
| Desktop services | Hyprland, PipeWire, etc. | TTY only |

---

## Related

- [04-POWER-MANAGEMENT](./04-POWER-MANAGEMENT.md) - TLP and power settings
- [../applications/02-BROWSERS](../applications/02-BROWSERS.md) - Browser RAM profiles (psd)
- [../hardware/10-EGPU](../hardware/10-EGPU.md) - GPU compute optimization
