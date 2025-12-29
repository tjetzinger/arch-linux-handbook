# 06 - Security

UFW firewall and systemd security features.

## UFW Firewall

Uncomplicated Firewall - iptables frontend.

### Status

```bash
systemctl status ufw
sudo ufw status verbose
```

### Current Rules

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere        # SSH
3000                       ALLOW IN    172.22.0.0/16   # Docker network
```

### Service Configuration

**Unit:** `/usr/lib/systemd/system/ufw.service`

```ini
[Unit]
Description=CLI Netfilter Manager
DefaultDependencies=no
After=systemd-sysctl.service
Before=sysinit.target

[Service]
Type=oneshot
ExecStart=/usr/lib/ufw/ufw-init start
ExecStop=/usr/lib/ufw/ufw-init stop
RemainAfterExit=yes
```

### Common Commands

```bash
# Enable/disable
sudo ufw enable
sudo ufw disable

# Status
sudo ufw status
sudo ufw status verbose
sudo ufw status numbered

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow port
sudo ufw allow 22/tcp
sudo ufw allow ssh

# Allow from specific IP
sudo ufw allow from 192.168.1.0/24 to any port 22

# Allow from Docker network
sudo ufw allow from 172.22.0.0/16 to any port 3000

# Delete rule
sudo ufw delete allow 22/tcp
sudo ufw delete 3   # By number

# Reset all rules
sudo ufw reset
```

### Configuration Files

```
/etc/ufw/
├── ufw.conf           # Main config
├── before.rules       # Rules before user rules
├── after.rules        # Rules after user rules
├── user.rules         # User-defined rules
└── applications.d/    # Application profiles
```

### Application Profiles

```bash
# List apps
sudo ufw app list

# Show app info
sudo ufw app info SSH

# Allow by app
sudo ufw allow 'SSH'
```

### Logging

```bash
# Set log level
sudo ufw logging low    # low, medium, high, full

# View logs
journalctl -k | grep UFW
sudo tail -f /var/log/ufw.log
```

## Systemd Security Features

### Service Hardening Options

Many services use these security directives:

```ini
[Service]
# User/Group
User=nobody
Group=nogroup
DynamicUser=true

# Filesystem
ProtectSystem=strict      # Read-only /usr, /boot, /efi
ProtectHome=true          # Hide /home
PrivateTmp=true           # Private /tmp
ReadOnlyPaths=/etc
ReadWritePaths=/var/lib/myapp

# Capabilities
CapabilityBoundingSet=
NoNewPrivileges=true

# Network
PrivateNetwork=true       # No network access
RestrictAddressFamilies=AF_UNIX AF_INET

# Kernel
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true

# Other
MemoryDenyWriteExecute=true
LockPersonality=true
RestrictNamespaces=true
```

### Checking Service Security

```bash
# Analyze service security
systemd-analyze security <service>

# Full report
systemd-analyze security

# Specific score
systemd-analyze security sshd
```

### Example: Tor Service

The tor.service shows extensive hardening:

```ini
[Service]
PrivateTmp=yes
PrivateDevices=yes
ProtectHome=yes
ProtectSystem=full
NoNewPrivileges=yes
```

## SSH Security

### sshd Configuration

**File:** `/etc/ssh/sshd_config`

Recommended settings:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
```

### Systemd Override

**File:** `/etc/systemd/system/sshd.service.d/override.conf`

```ini
[Unit]
After=tailscaled.service

[Service]
ExecStartPre=/bin/sleep 15
```

### Verify Config

```bash
sudo sshd -t
```

## fail2ban (Optional)

If installed, protects against brute force:

```bash
systemctl status fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

## Docker Security

Docker daemon runs as root. Security considerations:

### Socket Access

```bash
# Docker group membership grants root-equivalent access
groups
# Should show: docker
```

### UFW and Docker

Docker manipulates iptables directly. The rule:
```
3000 ALLOW IN 172.22.0.0/16
```
Allows traffic from Docker's proxy network.

### Container Security

See [../docker/08-SECURITY.md](../docker/08-SECURITY.md) for container hardening.

## Auditing

### Check Failed Logins

```bash
journalctl -u sshd | grep -i failed
```

### Check Authentication

```bash
journalctl _COMM=sudo
journalctl _COMM=sshd
```

### System Security Status

```bash
# Check listening ports
ss -tlnp

# Check open files
lsof -i

# Check running services
systemctl list-units --type=service --state=running
```

## Security Checklist

- [ ] UFW enabled with deny incoming default
- [ ] SSH key-only authentication
- [ ] SSH root login disabled
- [ ] Unnecessary services disabled
- [ ] Docker socket protected
- [ ] Regular system updates
- [ ] Snapper snapshots enabled
- [ ] Firewall logging enabled

## Quick Reference

```bash
# UFW
sudo ufw status verbose
sudo ufw allow <port>/tcp
sudo ufw delete allow <port>/tcp
sudo ufw logging low

# Systemd security
systemd-analyze security <service>

# SSH
sudo sshd -t
journalctl -u sshd

# Ports
ss -tlnp
```

## Related

- [03-NETWORK-SERVICES](./03-NETWORK-SERVICES.md) - SSH, Tailscale
- [../docker/08-SECURITY.md](../docker/08-SECURITY.md) - Container security
- [../networking/](../networking/) - Tailscale security
