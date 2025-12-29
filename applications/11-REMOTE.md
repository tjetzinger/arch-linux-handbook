# 11 - Remote Access

Remote desktop and connection tools.

## Remmina

Remote desktop client supporting multiple protocols.

### Launch

```bash
remmina
```

### Configuration

**Directory:** `~/.config/remmina/`

```
~/.config/remmina/
├── remmina.pref          # Preferences
└── *.remmina             # Saved connections
```

### Supported Protocols

| Protocol | Use Case |
|----------|----------|
| RDP | Windows Remote Desktop |
| VNC | VNC servers |
| SSH | SSH terminal |
| SFTP | File transfer |
| SPICE | Virtual machines |

### Connection Profiles

Save connection profiles for quick access:

1. Open Remmina
2. Click "+" to add new connection
3. Configure protocol and settings
4. Save profile

### RDP Settings

For Windows connections:

| Setting | Recommended |
|---------|-------------|
| Resolution | Auto or custom |
| Color depth | 32 bits |
| Network | Auto detect |
| Sound | Local |
| Clipboard | Enabled |

### VNC Settings

For VNC connections:

| Setting | Value |
|---------|-------|
| Color depth | True color (24 bits) |
| Quality | Best |
| Encryption | If supported |

## FreeRDP

Command-line RDP client.

### Configuration

**Directory:** `~/.config/freerdp/`

### Basic Usage

```bash
# Connect to Windows
xfreerdp /u:username /p:password /v:hostname

# Full screen
xfreerdp /f /u:username /v:hostname

# Custom resolution
xfreerdp /w:1920 /h:1080 /u:username /v:hostname

# With sound
xfreerdp /sound /u:username /v:hostname

# Clipboard sharing
xfreerdp /clipboard /u:username /v:hostname
```

### Common Options

| Option | Description |
|--------|-------------|
| `/v:` | Server hostname |
| `/u:` | Username |
| `/p:` | Password |
| `/d:` | Domain |
| `/f` | Fullscreen |
| `/w:` `/h:` | Resolution |
| `/clipboard` | Enable clipboard |
| `/sound` | Enable audio |
| `/drive:name,/path` | Share local folder |

## Virt-Viewer

Viewer for virtual machines (SPICE/VNC).

### Configuration

**Directory:** `~/.config/virt-viewer/`

### Launch

```bash
# Connect to VM
virt-viewer vm-name

# Remote connection
virt-viewer -c qemu+ssh://user@host/system vm-name
```

### With libvirt

```bash
# List VMs
virsh list --all

# View VM
virt-viewer win11
```

See [../virtualization/](../virtualization/) for VM documentation.

## SSH

### Terminal Access

```bash
# Connect to host (using SSH config)
ssh nas
ssh pve
ssh kali

# With specific user
ssh user@hostname

# With port
ssh -p 2222 user@hostname
```

See [08-GIT-SSH](./08-GIT-SSH.md) for full SSH configuration.

### SSH Tunnel

```bash
# Forward local port
ssh -L 8080:localhost:80 nas

# Remote port forward
ssh -R 8080:localhost:80 nas

# SOCKS proxy
ssh -D 1080 nas
```

### X11 Forwarding

```bash
# Enable X11 forwarding
ssh -X user@hostname

# Run GUI app
firefox
```

Note: Wayland doesn't support X11 forwarding directly. Use XWayland or remote desktop instead.

## SFTP / SCP

### File Transfer

```bash
# Copy file to remote
scp file.txt nas:~/

# Copy from remote
scp nas:~/file.txt ./

# Copy directory
scp -r directory/ nas:~/

# SFTP interactive
sftp nas
```

### SFTP Commands

```bash
sftp> ls              # List remote files
sftp> lls             # List local files
sftp> get file        # Download
sftp> put file        # Upload
sftp> cd dir          # Change remote dir
sftp> lcd dir         # Change local dir
sftp> quit            # Exit
```

## rsync

Efficient file synchronization.

```bash
# Sync to remote
rsync -avz local/ nas:~/backup/

# Sync from remote
rsync -avz nas:~/files/ local/

# With delete (mirror)
rsync -avz --delete local/ nas:~/backup/

# Dry run (preview)
rsync -avzn local/ nas:~/backup/
```

### Common Options

| Option | Description |
|--------|-------------|
| `-a` | Archive mode |
| `-v` | Verbose |
| `-z` | Compress |
| `-n` | Dry run |
| `--delete` | Delete extraneous |
| `--exclude` | Exclude pattern |
| `--progress` | Show progress |

## Wake-on-LAN

Wake remote machines:

```bash
# Install wakeonlan
sudo pacman -S wakeonlan

# Wake machine
wakeonlan AA:BB:CC:DD:EE:FF
```

## Integration with Desktop

### Quick Connect

From terminal:

```bash
# SSH
ssh nas

# Remote desktop
remmina -c ~/.config/remmina/nas.remmina
```

### Nautilus SFTP

Connect via file manager:

1. Press `Ctrl+L` for location bar
2. Enter: `sftp://user@hostname/path`

Or use "Other Locations" > "Connect to Server"

## Troubleshooting

### Connection Refused

```bash
# Check if service running on remote
systemctl status sshd

# Check firewall
sudo ufw status

# Test connectivity
ping hostname
nc -zv hostname 22
```

### RDP Black Screen

```bash
# Try different security
xfreerdp /sec:nla /u:user /v:host
xfreerdp /sec:tls /u:user /v:host
```

### Slow Connection

```bash
# Lower color depth
xfreerdp /bpp:16 /u:user /v:host

# Disable effects
xfreerdp /compression +aero /u:user /v:host
```

## Quick Reference

```bash
# Remote desktop
remmina                   # GUI client
xfreerdp /v:host /u:user  # RDP CLI

# Virtual machine viewer
virt-viewer vm-name

# SSH
ssh hostname              # Terminal access
scp file host:~/          # Copy file
rsync -avz src/ host:dst/ # Sync files

# Config locations
~/.config/remmina/
~/.config/freerdp/
~/.ssh/config
```

## Related

- [08-GIT-SSH](./08-GIT-SSH.md) - SSH configuration
- [../virtualization/](../virtualization/) - VM access
- [../networking/](../networking/) - Network configuration
