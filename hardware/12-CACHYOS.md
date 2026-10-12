# 12 - CachyOS Repository and Kernel

CachyOS provides x86-64-v3 optimized packages and performance-tuned kernels with sched-ext support.

## Overview

| Component | Details |
|-----------|---------|
| **Repositories** | cachyos, cachyos-v3, cachyos-core-v3, cachyos-extra-v3 |
| **Kernel** | linux-cachyos 6.18.2-2 |
| **Scheduler** | scx_lavd (sched-ext, via scx_loader) |
| **CPU requirement** | x86-64-v3 (AVX2, BMI2, FMA) |

## CPU Compatibility

### Check Instruction Set Support

```bash
/lib64/ld-linux-x86-64.so.2 --help 2>&1 | grep -E "x86-64-v[234]"
```

**Expected output for compatible CPU:**
```
x86-64-v3 (supported, searched)
x86-64-v2 (supported, searched)
```

### Instruction Set Levels

| Level | Features | Example CPUs |
|-------|----------|--------------|
| x86-64-v2 | SSE4.2, POPCNT | Intel Nehalem+, AMD Bulldozer+ |
| x86-64-v3 | AVX2, BMI2, FMA | Intel Haswell+, AMD Zen+ |
| x86-64-v4 | AVX-512 | Intel Ice Lake+, AMD Zen 4+ |

**ThinkPad X1C Gen 11 (i7-1370P):** Supports v3, NOT v4.

## Installation

### 1. Install CachyOS Repositories

```bash
# Download and run installer
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo

# Run installer (auto-detects CPU level)
yes | sudo ./cachyos-repo.sh

# Upgrade all packages to CachyOS versions
sudo pacman -Syu
```

This upgrades ~1000+ packages to x86-64-v3 optimized versions including:
- glibc, gcc, gcc-libs, binutils
- mesa, ffmpeg, python
- gtk3, gtk4, qt5/qt6
- zlib-ng-compat (replaces zlib)

### 2. Install CachyOS Kernel

```bash
sudo pacman -S linux-cachyos linux-cachyos-headers
```

### 3. Boot Entry and Kernel Updates

Follow [installation/09-CACHYOS-KERNEL](../installation/09-CACHYOS-KERNEL.md): the mkinitcpio preset writes kernel and initramfs straight to `/boot/EFI/arch/`, and the systemd-boot entry `linux-cachyos.conf` points there.

Do **not** copy the kernel with a pacman hook. The hook ran in the wrong order relative to mkinitcpio, so kernel and initramfs got out of sync after an upgrade and the system failed to boot. That is the incident in `installation/09`.

Live check:

```bash
grep -E '^(ALL_kver|default_image)' /etc/mkinitcpio.d/linux-cachyos.preset
# ALL_kver="/boot/EFI/arch/vmlinuz-linux-cachyos"
# default_image="/boot/EFI/arch/initramfs-linux-cachyos.img"
ls /etc/pacman.d/hooks/     # no linux-cachyos copy hook
```

## sched-ext Schedulers

CachyOS kernel includes sched-ext support for BPF-based schedulers.

### Install Schedulers

```bash
sudo pacman -S scx-scheds scx-tools
```

### Available Schedulers

| Scheduler | Best For |
|-----------|----------|
| `scx_bpfland` | General desktop, balanced (upstream's usual pick) |
| `scx_lavd` | Latency-sensitive, power-aware Auto mode (**live here**) |
| `scx_rusty` | Mixed workloads, tunable |
| `scx_flash` | Fairness, predictable performance |
| `scx_cosmos` | Locality-focused, general purpose |

### Configure Auto-Start

**Create config file:**

Live config (`scx_lavd`, Auto mode with power-aware tuning on this laptop):

```bash
sudo tee /etc/scx_loader.toml << 'EOF'
default_sched = "scx_lavd"
default_mode = "Auto"

[scheds.scx_lavd]
auto_mode = ["--autopower"]
EOF
```

**Enable service:**

```bash
sudo systemctl enable --now scx_loader
```

### Manual Control

```bash
# Check current scheduler
scxctl get

# Start scheduler
scxctl start --sched bpfland --mode auto

# Switch scheduler
scxctl switch --sched lavd --mode gaming

# Stop scheduler
scxctl stop

# Restore default from config
scxctl restore
```

### Scheduler Modes

| Mode | Use Case |
|------|----------|
| Auto | Balanced, default flags |
| Gaming | Performance, all cores |
| LowLatency | Audio, multimedia |
| PowerSave | Battery, efficiency |
| Server | Throughput over latency |

### Verify Scheduler Active

```bash
cat /sys/kernel/sched_ext/root/ops
# lavd_1.1.3_x86_64_unknown_linux_gnu
```

## Verification

### Check Kernel

```bash
uname -r
# 6.18.2-2-cachyos
```

### Check Scheduler

```bash
systemctl status scx_loader
cat /sys/kernel/sched_ext/root/ops
```

### List CachyOS Packages

```bash
# Count installed CachyOS packages
pacman -Sl cachyos-v3 cachyos-core-v3 cachyos-extra-v3 cachyos 2>/dev/null | grep "\[installed\]" | wc -l

# List key packages
pacman -Sl cachyos-v3 cachyos-core-v3 cachyos-extra-v3 cachyos 2>/dev/null | grep "\[installed\]" | awk '{print $2}' | grep -E "^(glibc|gcc|mesa|ffmpeg|python)"
```

## Performance Benefits

### x86-64-v3 Optimizations

- AVX2 vector instructions
- FMA (fused multiply-add)
- BMI1/BMI2 bit manipulation
- Estimated 5-15% improvement for CPU-intensive workloads

### CachyOS Kernel Features

- BORE scheduler (default, without sched-ext)
- sched-ext support (BPF schedulers)
- Additional performance patches
- x86-64-v3 compiled

### sched-ext Benefits

- Dynamic scheduler switching without reboot
- Specialized schedulers for different workloads
- Better latency for interactive tasks
- Core compaction for power saving (LAVD)

## Boot Options

### Available Kernels

| Entry | Kernel |
|-------|--------|
| `arch.conf` | linux (stock) |
| `arch-lts.conf` | linux-lts |
| `arch-zen.conf` | linux-zen |
| `linux-zen-x1c.conf` | linux-zen-x1c (custom) |
| `linux-cachyos.conf` | linux-cachyos |

### Set Default

```bash
# Set CachyOS as default
sudo bootctl set-default linux-cachyos.conf

# Revert to stock
sudo bootctl set-default arch.conf
```

## Rollback

### Snapper Snapshots

CachyOS installation creates snapper snapshots automatically.

```bash
# List recent snapshots
snapper list | tail -10

# Rollback if issues
sudo snapper rollback <snapshot-number>
```

### Remove CachyOS Kernel

```bash
sudo pacman -R linux-cachyos linux-cachyos-headers
sudo rm /boot/loader/entries/linux-cachyos.conf
sudo rm /boot/EFI/arch/vmlinuz-linux-cachyos
sudo rm /boot/EFI/arch/initramfs-linux-cachyos.img
sudo rm -f /etc/pacman.d/hooks/100-linux-cachyos.hook   # only if an old copy hook exists
```

### Remove CachyOS Repositories

To fully revert to Arch packages, remove CachyOS repos from `/etc/pacman.conf` and run `sudo pacman -Syu` to downgrade to Arch versions.

## Troubleshooting

### scx_loader Not Starting Scheduler

Check config file location:
```bash
cat /etc/scx_loader.toml
```

Must be `/etc/scx_loader.toml`, NOT `/etc/scx_loader/config.toml`.

### Scheduler Crashes

Check logs:
```bash
journalctl -u scx_loader -b 0
```

Try different scheduler or disable ananicy-cpp if installed.

### Boot Issues

Select fallback kernel from systemd-boot menu (stock `linux` or `linux-zen`).

## References

- [CachyOS Wiki - sched-ext Tutorial](https://wiki.cachyos.org/configuration/sched-ext/)
- [CachyOS Repository](https://github.com/CachyOS)
- [sched-ext GitHub](https://github.com/sched-ext/scx)

## Related

- [11-CUSTOM-KERNEL](./11-CUSTOM-KERNEL.md) - Custom linux-zen-x1c kernel
- [02-POWER-BATTERY](./02-POWER-BATTERY.md) - Power management
- [01-OVERVIEW](./01-OVERVIEW.md) - Hardware overview
