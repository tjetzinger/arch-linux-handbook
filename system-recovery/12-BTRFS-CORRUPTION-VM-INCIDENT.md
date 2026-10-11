# 12 - Btrfs Data Corruption & VM Image Incident

Diagnosing btrfs checksum corruption, distinguishing **on-disk rot** from
**transient in-memory (hardware) corruption**, and protecting VM images on the
`@vm` subvolume. Written from a real incident on `win11.qcow2`.

## Summary of the incident

| Stage | Finding |
|-------|---------|
| Trigger | `win11` VM felt slow; investigating disk I/O |
| First symptom | `qemu-img convert` of `/mnt/vm/win11.qcow2` aborted: `Input/output error` |
| Kernel log | `BTRFS warning ... csum failed root 323 ino 531 ... mirror 1` |
| SSD health | NVMe SMART **PASSED**, no errors — **not** a failing drive |
| Scrub #1 | 1.26 TiB scanned → **1 uncorrectable** csum error, isolated to `win11.qcow2` |
| Boot attempt | Windows 11 booted, but logged **20** csum errors during boot |
| After `sfc`/`chkdsk` | Windows **crashed**; **920** csum errors, at offsets scrub reads clean |
| Scrub #2 | Still only **1 uncorrectable** on disk — the 920 were **transient** |

**Root cause:** the data on disk is intact (scrub proves it), but it was being
corrupted **in memory, in flight, under load** — the same block read back with a
**different wrong checksum each time**. That signature = an active, load-dependent
hardware fault (marginal RAM, unstable XMP/EXPO memory overclock, or CPU/SoC
memory controller), which a single quick Memtest pass can miss.

## Diagnostic commands

```bash
# 1. See the csum failures and which inode (file) they hit
sudo dmesg | grep -i 'csum failed'
sudo dmesg | grep -i 'csum failed' | grep -oE 'ino [0-9]+' | sort | uniq -c

# 2. Resolve the inode to a filename
sudo btrfs inspect-internal inode-resolve <ino> /mnt/vm

# 3. Rule out hardware drive failure
sudo smartctl -H -l error /dev/nvme0n1          # want: PASSED / No Errors Logged
sudo btrfs device stats /mnt/vm                 # corruption_errs counter

# 4. Full-filesystem scrub - enumerates EVERY corrupted file (can't repair on
#    single-device btrfs, but tells you the true scope)
sudo btrfs scrub start /mnt/vm
sudo btrfs scrub status /mnt/vm                  # poll until "finished"
```

### The key distinction: on-disk rot vs transient corruption

- **On-disk rot:** `btrfs scrub` reports the same bad block(s) every run; the file
  is genuinely damaged. Single-device btrfs cannot repair (no second copy).
- **Transient / in-memory corruption:** the guest or an app hits many csum errors,
  but a **scrub reads those same offsets clean**, and repeated reads of one block
  produce **different** computed checksums. The bytes on disk are fine — they are
  corrupted after being read, in RAM/DMA. **This points at hardware, not the disk.**

```bash
# Tell them apart: compare guest-visible error count vs what scrub finds on disk.
# Many guest errors + scrub finds ~none at those offsets = transient (hardware).
sudo dmesg | grep -c 'ino <ino>'                # guest-visible csum reads
sudo btrfs scrub status /mnt/vm | grep -i uncorrect   # persistent on-disk damage
```

## Hardware root-cause (do this BEFORE trusting the machine under load)

A healthy SSD + checksum mismatches that change per read = memory-path fault.

1. **Memtest86+ — multiple full passes / overnight** (already a systemd-boot entry
   here; `memtest86+-efi` installed). One quick pass is not enough for marginal faults.
2. **Disable XMP/EXPO in BIOS** and re-test at JEDEC speeds. An unstable memory
   overclock is the most common "passes memtest briefly, corrupts under real load" cause.
3. If still failing: test **one DIMM at a time**. On soldered-RAM laptops
   (ThinkPad X1 Carbon), a clean overnight memtest + no speed tweaks is the main
   lever; persistent corruption becomes a mainboard/CPU RMA case.

## Recovery of a corrupted VM image (no backup / no snapshot)

If the image is genuinely damaged on disk and there is no backup or snapshot:

```bash
# Best-effort salvage: copy skipping unreadable blocks, then repair inside guest.
# (btrfs returns EIO on bad extents; ddrescue/dd skip them, zero-filling the gaps.)
ddrescue /mnt/vm/win11.qcow2 /mnt/vm/win11.salvaged.qcow2 /mnt/vm/win11.mapfile
# then boot Windows and run:  sfc /scannow  &&  chkdsk C: /f /r
```
Data in the corrupted regions is already lost. If a bad block landed in qcow2
metadata, the image may not open — then rebuild from scratch.

> Do **not** keep booting a VM that triggers transient corruption — each run risks
> writing more bad data. Clear the hardware first.

## Prevention: protect the `@vm` subvolume

The incident was unrecoverable because `@vm` had **no snapshots and was not in Borg**
(Borg backs up `/home/tt` only; `/mnt/vm` was outside its scope).

### VM disk config (performance + safety on btrfs)

```bash
# nodatacow for VM images (avoids CoW-on-qcow2 fragmentation). +C on the DIRECTORY
# makes NEW files inherit it (existing files must be recreated to take effect).
chattr +C /mnt/vm
lsattr -d /mnt/vm                 # expect the 'C' flag

# Match qcow2 cache mode to the image type:
#   nodatacow image -> cache='none'  io='native'   (optimal)
#   datacow  image  -> cache='writeback'           (safer on btrfs)
virsh dumpxml <vm> --inactive > /tmp/vm.xml
# edit <driver ... cache='...'/> then:
virsh define /tmp/vm.xml
```

### Snapshot protection (Snapper config for `@vm`)

```bash
sudo snapper -c vm create-config /mnt/vm
# Keep it inert until there is a known-good image, then enable the timeline:
sudo snapper -c vm set-config TIMELINE_CREATE=no NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=3
sudo snapper list-configs                       # should list 'vm -> /mnt/vm'

# Manual snapshot before risky VM changes:
sudo snapper -c vm create -d "before <change>"
# Enable scheduled snapshots later: set TIMELINE_CREATE=yes
```

### Backup coverage

Add VM images to Borg **with the guest shut down** (a live qcow2 backs up
inconsistently). See [07-BORG-BACKUP-AUTOMATION](./07-BORG-BACKUP-AUTOMATION.md).
Add `/mnt/vm` as a backup path (it is currently neither included nor snapshotted).

## Related

- [06-BTRFS-MAINTENANCE](./06-BTRFS-MAINTENANCE.md) - scrub, scheduling, health
- [09-SUBVOLUME-STRATEGY](./09-SUBVOLUME-STRATEGY.md) - `@vm` and subvolume layout
- [04-BACKUP-STRATEGY-OVERVIEW](./04-BACKUP-STRATEGY-OVERVIEW.md) - backup layers
- `virtualization/08-PERFORMANCE.md` - VM tuning (CPU pinning, disk, virtio)
