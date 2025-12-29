# GNOME Keyring & SSH Agent

Secure credential and SSH key management for Hyprland.

## Overview

GNOME Keyring provides:
- Secure storage for passwords and secrets
- SSH agent via gcr-ssh-agent (stores SSH passphrases)
- Automatic unlock on login via PAM integration

**Unified solution:** All SSH operations (terminal, VS Code, GUI apps) use the same agent.

## Installation

```bash
sudo pacman -S gnome-keyring gcr-4 seahorse libsecret
```

| Package | Purpose |
|---------|---------|
| `gnome-keyring` | Keyring daemon and PAM module |
| `gcr-4` | GCR SSH agent (gcr-ssh-agent) |
| `seahorse` | GUI for managing stored credentials |
| `libsecret` | Secret storage library |

## SSH Agent Setup

### Enable gcr-ssh-agent

```bash
# Enable the GCR SSH agent socket
systemctl --user enable --now gcr-ssh-agent.socket

# Disable conflicting agents
systemctl --user disable --now ssh-agent.socket 2>/dev/null
```

### Set SSH_AUTH_SOCK Globally

**File:** `~/.config/environment.d/ssh-agent.conf`
```ini
SSH_AUTH_SOCK=/run/user/1000/gcr/ssh
```

This ensures all applications (terminals, VS Code, GUI apps) use the same agent.

### Add SSH Key to Keyring

Run once to store passphrase permanently:

```bash
/usr/lib/seahorse/ssh-askpass ~/.ssh/id_ed25519
```

A dialog prompts for the passphrase. Check "Automatically unlock" to store it in the keyring.

### Verify Setup

```bash
# Check agent is running
systemctl --user status gcr-ssh-agent.socket

# Check socket exists
ls -la /run/user/1000/gcr/ssh

# Check key is loaded
ssh-add -l
```

## PAM Integration (Auto-unlock on Login)

For automatic keyring unlock when logging in via SDDM:

**`/etc/pam.d/sddm`**:
```
auth       optional    pam_gnome_keyring.so
password   optional    pam_gnome_keyring.so    use_authtok
session    optional    pam_gnome_keyring.so
```

**Important:** The keyring password must match your login password for auto-unlock.

## Shell Configuration

The `environment.d` config works for GUI apps launched by systemd, but terminal sessions need an explicit export.

**File:** `~/.config/zshrc/20-customization`
```bash
# SSH agent - managed by gcr-ssh-agent (GNOME Keyring)
# Passphrase stored in keyring, unlocked at login
# Service: systemctl --user status gcr-ssh-agent.socket
export SSH_AUTH_SOCK=/run/user/1000/gcr/ssh
```

This ensures both terminal SSH and GUI applications use the same agent.

## Managing Credentials

### GUI (Seahorse)

```bash
seahorse
```

- **Passwords** tab: Stored website/application passwords
- **OpenSSH keys** tab: SSH keys with stored passphrases
- Right-click **Login** keyring > **Change Password**: Set to match login password

### Command Line

```bash
# List loaded SSH keys
ssh-add -l

# Add a key (prompts for passphrase)
ssh-add ~/.ssh/id_ed25519

# Remove a key
ssh-add -d ~/.ssh/id_ed25519

# Remove all keys
ssh-add -D
```

### Store Passphrase Permanently

```bash
# GUI method (recommended)
/usr/lib/seahorse/ssh-askpass ~/.ssh/id_ed25519

# Or via secret-tool
secret-tool store --label="SSH Key" unique "ssh-store:/home/tt/.ssh/id_ed25519"
```

## Troubleshooting

### SSH Still Asking for Passphrase

1. Check correct agent is being used:
   ```bash
   echo $SSH_AUTH_SOCK
   # Should be: /run/user/1000/gcr/ssh
   ```

2. Check key is loaded:
   ```bash
   ssh-add -l
   ```

3. Check no conflicting agents:
   ```bash
   pgrep -a ssh-agent
   # Should be empty (gcr-ssh-agent doesn't show as ssh-agent)
   ```

4. Re-add key to keyring:
   ```bash
   /usr/lib/seahorse/ssh-askpass ~/.ssh/id_ed25519
   ```

### Clear Stored SSH Passphrase

```bash
# Find the stored passphrase
secret-tool search --all unique "ssh-store:/home/tt/.ssh/id_ed25519"

# Clear it
secret-tool clear unique "ssh-store:/home/tt/.ssh/id_ed25519"

# Restart agent
systemctl --user restart gcr-ssh-agent.socket
```

### Keyring Not Unlocking Automatically

1. Verify PAM configuration in `/etc/pam.d/sddm`
2. Ensure keyring password matches login password:
   ```bash
   seahorse  # Right-click Login keyring > Change Password
   ```

### Reset Keyring

If keyring is corrupted or password doesn't match:

```bash
# Delete existing keyring (loses stored passwords!)
rm ~/.local/share/keyrings/login.keyring

# Log out and back in - new keyring created with login password
```

### VS Code Not Using Agent

1. Restart VS Code after setting up environment.d
2. Or set in VS Code settings:
   ```json
   "git.terminalGitEditor": true
   ```

## GCR Prompter for Wayland

For GUI passphrase dialogs on Hyprland:

**File:** `~/.local/share/dbus-1/services/org.gnome.keyring.SystemPrompter.service`
```ini
[D-BUS Service]
Name=org.gnome.keyring.SystemPrompter
Exec=/bin/sh -c 'GDK_BACKEND=wayland exec /usr/lib/gcr-prompter'
```

```bash
# Reload D-Bus config
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
```

## File Locations

| Path | Purpose |
|------|---------|
| `~/.config/zshrc/20-customization` | SSH_AUTH_SOCK export for terminals |
| `~/.config/environment.d/ssh-agent.conf` | SSH_AUTH_SOCK for GUI apps |
| `~/.local/share/keyrings/` | Stored keyrings (encrypted) |
| `/run/user/1000/gcr/ssh` | GCR SSH agent socket |
| `/run/user/1000/keyring/` | GNOME Keyring socket directory |
| `/etc/pam.d/sddm` | SDDM PAM configuration |

## Quick Reference

```bash
# Check agent status
systemctl --user status gcr-ssh-agent.socket

# List loaded keys
ssh-add -l

# Add key with GUI dialog (stores passphrase)
/usr/lib/seahorse/ssh-askpass ~/.ssh/id_ed25519

# Manage keyring GUI
seahorse

# Check SSH_AUTH_SOCK
echo $SSH_AUTH_SOCK
# Expected: /run/user/1000/gcr/ssh
```

## Related

- [08-LOCKSCREEN.md](./08-LOCKSCREEN.md) - hyprlock configuration
- [13-REMOTE-ACCESS.md](./13-REMOTE-ACCESS.md) - VNC over SSH
- [../systemd/07-DESKTOP-SERVICES.md](../systemd/07-DESKTOP-SERVICES.md) - User services
