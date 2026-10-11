# 12 - Btrfs Data Corruption & VM Image Incident

Diagnosing btrfs checksum corruption, distinguishing **on-disk rot** from
**transient checksum errors**, and protecting VM images on the `@vm` subvolume.
Written from a real incident on `win11.qcow2` (2026-08-13/14).

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
| Cache mode switched | win11 ran 2 more times with `cache='writeback'`: **no** transient errors, only the 1 bad block (same checksum every read) |

**Root cause (most likely, re-analysed 2026-10-11):** two separate problems.

1. **Transient errors = direct I/O reads, not hardware.** win11 ran with
   `cache='none'` on a datacow (checksummed) image. With direct I/O, btrfs
   verifies the checksum on the guest's own read buffer. Windows can change that
   buffer while the read is still in flight, so the computed checksum differs
   on every read and btrfs returns `EIO`. The kernel 6.14 fix (fallback to
   buffered I/O) covers writes only.

   | Runs | Cache mode | csum errors in the kernel log |
   |------|------------|-------------------------------|
   | 2026-08-13, 2 runs | `none` (direct I/O) | 495 at 86 offsets; 56 offsets gave a different wrong checksum per read |
   | 2026-08-14, 2 runs | `writeback` (page cache) | 10, all at one offset, always the same checksum |

   A RAM fault would also corrupt reads through the page cache. The
   `writeback` runs show none of that. Caveat: the 08-14 runs may have had
   lighter load, so hardware is unlikely, not ruled out.
2. **One real bad block on disk** (offset `22750773248` in `win11.qcow2`). Scrub
   finds it every run, with the same checksum. Single-device btrfs has no second
   copy to repair it from.

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

### The key distinction: on-disk rot vs transient errors

- **On-disk rot:** `btrfs scrub` reports the same bad block(s) every run; the file
  is genuinely damaged. Single-device btrfs cannot repair (no second copy).
- **Transient errors:** the guest or an app hits many csum errors, but a
  **scrub reads those same offsets clean**, and repeated reads of one block
  produce **different** computed checksums. The bytes on disk are fine.
  - First check the cache mode: `cache='none'` on a datacow image explains this
    (see Root cause). Switch to `writeback` and re-test.
  - Errors that persist with `writeback` point at hardware (RAM, memory controller).

```bash
# Tell them apart: compare guest-visible error count vs what scrub finds on disk.
# Many guest errors + scrub finds ~none at those offsets = transient.
virsh dumpxml <vm> | grep "driver name='qemu'"   # cache='none'? -> direct I/O reads
lsattr /mnt/vm/*.qcow2                           # no 'C' = datacow (checksummed)
sudo dmesg | grep -c 'ino <ino>'                # guest-visible csum reads
sudo btrfs scrub status /mnt/vm | grep -i uncorrect   # persistent on-disk damage
```

## Rule out hardware (if errors persist with `writeback`)

A healthy SSD + checksum mismatches that change per read, **with buffered I/O**,
= memory-path fault.

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

> Do **not** keep booting a VM that triggers transient errors. Switch it to
> `cache='writeback'` first; if errors continue, clear the hardware before the next run.

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

## Follow-up 2026-10-11: removing the bad block

The one real bad block (offset `22750773248` in `win11.qcow2`) was still there two months later, and nothing else had gone bad (`btrfs scrub`: `csum=1`, same offset).

**Find which guest file owns it** (VM off, all read-only):

```bash
# 1. Image offset -> guest disk offset
sudo qemu-img map -U --output=json /mnt/vm/win11.qcow2 > map.json
#    find the entry where offset <= 22750773248 < offset+length,
#    guest = start + (22750773248 - offset)   -> 27227471872 (25.36 GiB)

# 2. Guest offset -> partition (GPT read from the image) -> NTFS cluster
#    C: starts at sector 239616: (27227471872 - 239616*512) / 4096 = 6617380

# 3. Export C: read-only as a file and ask NTFS who owns the cluster
sudo qemu-storage-daemon \
  --blockdev driver=file,node-name=f,filename=/mnt/vm/win11.qcow2,read-only=on,locking=off \
  --blockdev driver=qcow2,node-name=q,file=f,read-only=on \
  --blockdev driver=raw,node-name=c,file=q,offset=$((239616*512)),size=<partition bytes>,read-only=on \
  --export type=fuse,id=e,node-name=c,mountpoint=/path/to/c.raw,writable=off --daemonize
sudo ntfscluster -f -c 6617380 /path/to/c.raw
#   -> Inode 227634 /Windows/MEMORY.DMP/$DATA
```

The bad block sat in `C:\Windows\MEMORY.DMP`, an old crash dump. No system or user file was damaged.

**Fix:** delete `MEMORY.DMP` in Windows. With `discard='unmap'` the TRIM punched a hole in the qcow2 file, so the live image no longer referenced the bad extent (`filefrag` showed no extent at that offset, a direct read returned no I/O error). The `vm` snapper snapshots still held the old extent, so scrub reported it until they were deleted:

```bash
sudo snapper -c vm delete <numbers>
sudo btrfs subvolume sync /mnt/vm
sudo btrfs scrub start -B /     # 621.52 GiB, no errors found
```

No image rebuild was needed. On the same day win11 also stopped booting after host updates (kernel 7.2 offers MBEC to nested guests, which clashes with CET and nested APICv under Windows VBS); that was a separate problem, see [virtualization/04 - Boot Loop After a Host Update](../virtualization/04-WINDOWS-VM.md#boot-loop-after-a-host-update-vbs--nested-virtualization).

## Related

- [06-BTRFS-MAINTENANCE](./06-BTRFS-MAINTENANCE.md) - scrub, scheduling, health
- [09-SUBVOLUME-STRATEGY](./09-SUBVOLUME-STRATEGY.md) - `@vm` and subvolume layout
- [04-BACKUP-STRATEGY-OVERVIEW](./04-BACKUP-STRATEGY-OVERVIEW.md) - backup layers
- `virtualization/08-PERFORMANCE.md` - VM tuning (CPU pinning, disk, virtio)
