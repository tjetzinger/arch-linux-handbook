# 11 - Custom Kernel (linux-zen-x1c)

Custom optimized kernel for ThinkPad X1 Carbon Gen 11.

## Overview

| Property | Value |
|----------|-------|
| Kernel | linux-zen-x1c |
| Base | linux-zen 6.18.2.zen2 |
| Build method | localmodconfig + menuconfig |
| Build location | `~/Workspace/linux-zen-x1c/` |

## Why Custom Kernel?

- **Smaller size**: 30MB vs 140MB package
- **Faster boot**: Fewer modules to load
- **Less memory**: Only needed drivers loaded
- **Optimized**: Tuned for Raptor Lake + interactivity

## Size Comparison

| Component | linux-zen-x1c | Stock linux-zen |
|-----------|---------------|-----------------|
| Kernel | 18 MB | ~35 MB |
| Initramfs | 24 MB | ~40 MB |
| Package | 30 MB | ~140 MB |

## Key Optimizations

### Enabled
- Intel Raptor Lake CPU family (`CONFIG_X86_NATIVE_CPU`)
- Full dynticks (NO_HZ_FULL)
- Low-latency preemption (PREEMPT)
- BORE scheduler (interactivity)
- ZSTD compression
- Intel P-State + RAPL
- Intel Xe + i915 graphics
- Intel WiFi/Bluetooth
- Intel HW RNG (`CONFIG_HW_RANDOM_INTEL`)
- SOF audio (`CONFIG_SND_SOC_SOF_ALDERLAKE`)
- USB audio (`CONFIG_SND_USB_AUDIO`) - eMeet Luna, dock audio
- Bluetooth HID (`CONFIG_BT_HIDP`, `CONFIG_UHID`) - Logitech keyboards/mice
- USB networking (`CONFIG_USB_USBNET`, `CONFIG_USB_NET_CDCETHER`) - dock ethernet
- ThinkPad ACPI
- NVMe, Btrfs, dm-crypt
- KVM Intel

### Disabled
- AMD CPU/GPU/KVM support
- Nvidia graphics
- Intel AVS audio driver (conflicts with SOF)
- Other wireless drivers
- Legacy hardware (FireWire, PCMCIA, etc.)
- Server/datacenter features
- Unused filesystems

## Boot Entry

**File:** `/boot/loader/entries/linux-zen-x1c.conf`

```ini
title Arch Linux (Zen X1C)
linux /vmlinuz-linux-zen-x1c
initrd /intel-ucode.img
initrd /initramfs-linux-zen-x1c.img
options rd.luks.name=dd8c7166-cbef-454c-a046-9a7efc26bb60=cryptroot root=/dev/mapper/cryptroot rd.luks.key=... rootflags=subvol=@arch rw
```

## Usage

### Select at boot
Choose "Arch Linux (Zen X1C)" from systemd-boot menu.

### Verify
```bash
uname -r
# 6.18.2-zen2-1-zen-x1c
```

### Set as default
```bash
sudo bootctl set-default linux-zen-x1c.conf
```

### Revert to stock
```bash
sudo bootctl set-default arch-zen.conf
```

## Updating

### When linux-zen updates upstream

```bash
cd ~/Workspace/linux-zen-x1c

# Pull latest PKGBUILD
git -C upstream-pkgbuild pull
cp upstream-pkgbuild/PKGBUILD .
cp upstream-pkgbuild/config .

# Re-apply customizations to PKGBUILD:
# - Change pkgbase=linux-zen-x1c
# - Add localmodconfig section in prepare()
# - Add menuconfig call

# Capture current modules
lsmod > /tmp/modules.lst

# Build
MAKEFLAGS="-j18" makepkg -s

# Install
sudo pacman -U linux-zen-x1c-*.pkg.tar.zst linux-zen-x1c-headers-*.pkg.tar.zst
```

### Quick rebuild (same version)

```bash
cd ~/Workspace/linux-zen-x1c
MAKEFLAGS="-j18" makepkg -ef  # -e = use existing source
sudo pacman -U linux-zen-x1c-*.pkg.tar.zst
```

## Adding Hardware Support

If new hardware doesn't work on custom kernel:

1. Boot stock kernel (`linux-zen`)
2. Connect hardware
3. Find module: `lsmod | grep <name>`
4. Add to list: `echo "module_name" >> /tmp/modules.lst`
5. Rebuild kernel

**Supported hardware:**

| Hardware | Module | Config |
|----------|--------|--------|
| Dock ethernet | `cdc_ether`, `usbnet` | `CONFIG_USB_USBNET`, `CONFIG_USB_NET_CDCETHER` |
| Logitech Bluetooth | `hid_logitech_hidpp`, `hidp` | `CONFIG_HID_LOGITECH_HIDPP`, `CONFIG_BT_HIDP` |
| Logitech USB receiver | `hid_logitech_dj` | `CONFIG_HID_LOGITECH_DJ` |
| USB audio (eMeet Luna) | `snd_usb_audio` | `CONFIG_SND_USB_AUDIO` |
| USB storage | `usb_storage`, `uas` | `CONFIG_USB_STORAGE`, `CONFIG_USB_UAS` |
| YubiKey | `hid` | `CONFIG_HID` |

## Benchmarking

```bash
# Run benchmark script
~/Workspace/linux-zen-x1c/benchmark.sh

# Results saved to:
~/Workspace/linux-zen-x1c/benchmark-results/
```

### Results Summary (vs Stock linux-zen)

| Metric | Custom | Stock | Winner |
|--------|--------|-------|--------|
| CPU Performance | 39,927 ev/s | 40,109 ev/s | Tie (<1%) |
| Compilation Speed | ~4.9s | ~4.9s | Tie |
| Power (load) | 19W | 18W | Stock (+5%) |
| Kernel Size | 9.9 MB | 14.6 MB | Custom (-32%) |
| Modules | 48 | 92 | Custom (-48%) |

**Key findings:**
- CPU/compilation performance identical (variance is thermal, not kernel)
- Both have same I/O schedulers (BFQ, kyber, mq-deadline)
- Custom has `CONFIG_X86_NATIVE_CPU=y` (Raptor Lake optimizations)
- Stock slightly more power efficient (~5%)

Full results: `~/Workspace/linux-zen-x1c/benchmark-results/comparison.md`

## Troubleshooting

### Kernel doesn't boot
Select "Arch Linux (Zen)" from boot menu - fallback is always available.

### Hardware not working
Boot stock kernel, check `lsmod`, add module to list, rebuild.

### No audio (sof-hda-dsp)
**Symptom**: `aplay -l` shows no soundcards, kernel log shows AVS firmware errors.

**Cause**: Intel AVS driver claims audio device but lacks firmware. SOF driver should be used instead.

**Fix**: Disable AVS in kernel config:
```bash
cd ~/Workspace/linux-zen-x1c/src/linux-*/
scripts/config --disable CONFIG_SND_SOC_INTEL_AVS
scripts/config --module CONFIG_SND_SOC_SOF_ALDERLAKE
make olddefconfig
```
Then rebuild kernel.

### Sudo password loop (fingerprint)
**Symptom**: Sudo keeps asking for password, never accepts it.

**Cause**: `pam_fprintd.so` fails when fingerprint sensor communication is broken, causing auth loop.

**Fix**: Enable Intel HW RNG:
```bash
scripts/config --module CONFIG_HW_RANDOM_INTEL
make olddefconfig
```
Then rebuild kernel.

### mkinitcpio module errors
**Symptom**: Errors like `module not found: 'crypto_lz4'`, `'dm_integrity'`

**Cause**: Modules referenced in `/etc/mkinitcpio.conf` but not in custom kernel.

**Fix for crypto_lz4 / dm_integrity** (add to kernel):
```bash
cd ~/Workspace/linux-zen-x1c/src/linux-*/
scripts/config --module CONFIG_CRYPTO_LZ4
scripts/config --module CONFIG_CRYPTO_LZ4HC
scripts/config --module CONFIG_DM_INTEGRITY
make olddefconfig
```
Then rebuild kernel.

### Remove custom kernel
```bash
sudo pacman -R linux-zen-x1c linux-zen-x1c-headers
sudo rm /boot/loader/entries/linux-zen-x1c.conf
```

## System Configuration

### Separate mkinitcpio config
Custom kernel uses `/etc/mkinitcpio-zen-x1c.conf` (without nvidia modules):

```bash
# Preset: /etc/mkinitcpio.d/linux-zen-x1c.preset
ALL_config="/etc/mkinitcpio-zen-x1c.conf"
```

### Nvidia removed system-wide
Nvidia packages have been removed from the system (no eGPU use):

```bash
# Removed packages:
# nvidia-open, nvidia-utils, nvidia-settings, libxnvctrl
# nvidia-container-toolkit, libnvidia-container
# egl-gbm, egl-wayland, egl-wayland2, egl-x11

# Removed from /etc/mkinitcpio.conf MODULES array
# Removed nvidia_drm.modeset=0 from boot entries
```

Only `linux-firmware-nvidia` remains (required by `linux-firmware`).

## Build Files

| File | Location |
|------|----------|
| PKGBUILD | `~/Workspace/linux-zen-x1c/PKGBUILD` |
| Config | `~/Workspace/linux-zen-x1c/config` |
| Boot entry | `/boot/loader/entries/linux-zen-x1c.conf` |
| Benchmark | `~/Workspace/linux-zen-x1c/benchmark.sh` |
| Full docs | `~/Workspace/linux-zen-x1c/README.md` |

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Hardware overview
- [02-POWER-BATTERY](./02-POWER-BATTERY.md) - Power management
- [../installation/](../installation/) - System installation
