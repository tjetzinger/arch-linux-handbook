# 07 - Biometrics

Fingerprint reader setup and configuration.

## Hardware

**Synaptics Prometheus Fingerprint Reader**

```bash
lsusb | grep Synaptics
```

```
Synaptics, Inc. Prometheus Fingerprint Reader (06cb:00fc)
```

## Software Stack

| Component | Purpose |
|-----------|---------|
| fprintd | Fingerprint daemon |
| libfprint | Low-level library |
| pam-fprint | PAM module for auth |

### Service Status

```bash
systemctl status fprintd
```

Note: fprintd uses D-Bus activation, so it starts on demand.

## Enrolled Fingerprints

```bash
fprintd-list $USER
```

Current enrollments:
```
Device: Synaptics Sensors (press)
Fingerprints for user tt:
 - #0: right-index-finger
```

## Enrollment

### Enroll New Fingerprint

```bash
fprintd-enroll
```

Available fingers:
- left-thumb
- left-index-finger
- left-middle-finger
- left-ring-finger
- left-little-finger
- right-thumb
- right-index-finger
- right-middle-finger
- right-ring-finger
- right-little-finger

### Enroll Specific Finger

```bash
fprintd-enroll -f right-thumb
```

### Verify Enrollment

```bash
fprintd-verify
```

## Delete Fingerprints

```bash
# Delete all fingerprints
fprintd-delete $USER

# Re-enroll after deletion
fprintd-enroll
```

## PAM Configuration

### Enable for sudo

**File:** `/etc/pam.d/sudo`

Add at the top:
```
auth    sufficient    pam_fprintd.so
```

Full file:
```
auth    sufficient    pam_fprintd.so
auth    include       system-auth
account include       system-auth
session include       system-auth
```

### Enable for Login (SDDM)

**File:** `/etc/pam.d/sddm`

```
auth    sufficient    pam_fprintd.so
auth    include       system-login
...
```

### Enable for Polkit

**File:** `/etc/pam.d/polkit-1`

```
auth    sufficient    pam_fprintd.so
auth    include       system-auth
...
```

### Enable for Screen Lock

Depends on your screen locker. For swaylock:

**File:** `/etc/pam.d/swaylock`

```
auth    sufficient    pam_fprintd.so
auth    include       system-auth
```

## Usage

### sudo with Fingerprint

After PAM configuration:
```bash
sudo pacman -Syu
# Prompts for fingerprint, falls back to password
```

### Login

At SDDM login screen:
1. Select user
2. Touch fingerprint sensor
3. Or type password

### Polkit Prompts

GUI password prompts (like in Nautilus) will accept fingerprint.

## Security Considerations

### Fingerprint vs Password

| Aspect | Fingerprint | Password |
|--------|-------------|----------|
| Convenience | High | Low |
| Security | Lower | Higher |
| Revocable | No | Yes |
| Brute-force | Difficult | Depends |

### Recommendations

1. **Keep password as fallback** - Don't disable password auth
2. **Use strong password** - Fingerprint is convenience, not primary auth
3. **Limit sudo timeout** - `Defaults timestamp_timeout=5`

## Multiple Users

Each user can enroll their own fingerprints:

```bash
# As each user
fprintd-enroll
fprintd-list $USER
```

## Troubleshooting

### Reader Not Detected

```bash
# Check USB
lsusb | grep -i finger

# Check dmesg
dmesg | grep -i finger

# Check fprintd
systemctl status fprintd
journalctl -u fprintd
```

### Enrollment Fails

```bash
# Ensure finger is clean and dry
# Try different finger position
# Press firmly but not too hard

# Check for errors
fprintd-enroll -v
```

### Authentication Fails

```bash
# Verify enrollment
fprintd-verify

# Check PAM config
cat /etc/pam.d/sudo

# Check logs
journalctl | grep fprintd
```

### Multiple Failed Attempts

The sensor may lock after too many failures:

```bash
# Wait a few seconds
# Try password instead
# Re-attempt fingerprint
```

## Device Information

```bash
# fprintd device info
fprintd-list $USER

# Detailed info via D-Bus
busctl --user introspect net.reactivated.Fprint /net/reactivated/Fprint/Device/0
```

## Disabling Fingerprint Auth

### Temporarily

```bash
# Use password instead of fingerprint when prompted
# Or press Enter for password prompt
```

### Permanently

Remove PAM configuration:
```bash
# Edit /etc/pam.d/sudo, /etc/pam.d/sddm, etc.
# Remove or comment out:
# auth    sufficient    pam_fprintd.so
```

## Quick Reference

```bash
# List enrolled fingerprints
fprintd-list $USER

# Enroll fingerprint
fprintd-enroll

# Enroll specific finger
fprintd-enroll -f left-thumb

# Verify fingerprint
fprintd-verify

# Delete fingerprints
fprintd-delete $USER

# Check device
lsusb | grep Synaptics

# Logs
journalctl | grep fprintd
```

## PAM Files Summary

| File | Purpose |
|------|---------|
| /etc/pam.d/sudo | sudo authentication |
| /etc/pam.d/sddm | Display manager login |
| /etc/pam.d/polkit-1 | GUI privilege prompts |
| /etc/pam.d/swaylock | Screen lock |
| /etc/pam.d/system-local-login | TTY login |

## Related

- [../systemd/06-SECURITY.md](../systemd/06-SECURITY.md) - Security configuration
- [01-OVERVIEW](./01-OVERVIEW.md) - Hardware specifications
