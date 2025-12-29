# 08 - Git & SSH

Git configuration, GitHub CLI, and SSH profiles.

## Git Configuration

### User Identity

**File:** `~/.gitconfig`

```ini
[user]
    name = Your Name
    email = user@example.com

[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential

[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
```

### Credential Helper

GitHub CLI handles authentication for both GitHub and Gist.

### Common Git Commands

```bash
# Status and info
git status              # Working tree status
git log --oneline -10   # Recent commits
git diff                # Unstaged changes
git diff --staged       # Staged changes

# Branching
git branch              # List branches
git checkout -b <name>  # Create and switch
git switch <branch>     # Switch branch
git merge <branch>      # Merge branch

# Committing
git add <file>          # Stage file
git add .               # Stage all
git commit -m "msg"     # Commit
git commit --amend      # Amend last commit

# Remote
git push                # Push to remote
git pull                # Fetch and merge
git fetch               # Fetch only
```

### Git Aliases (via oh-my-zsh)

| Alias | Command |
|-------|---------|
| `gst` | git status |
| `ga` | git add |
| `gc` | git commit |
| `gp` | git push |
| `gpl` | git pull |
| `gco` | git checkout |
| `gcb` | git checkout -b |
| `gb` | git branch |
| `gd` | git diff |
| `glog` | git log --oneline |

## GitHub CLI

### Authentication

```bash
# Login
gh auth login

# Check status
gh auth status

# Refresh
gh auth refresh
```

### Configuration

**File:** `~/.config/gh/config.yml`

```yaml
version: 1
git_protocol: https
prompt: enabled
aliases:
    co: pr checkout
spinner: enabled
```

### Common Commands

```bash
# Repository
gh repo view              # View current repo
gh repo view --web        # Open in browser
gh repo clone <repo>      # Clone repository
gh repo create            # Create new repo

# Pull Requests
gh pr list                # List PRs
gh pr view <num>          # View PR
gh pr create              # Create PR
gh pr checkout <num>      # Check out PR branch
gh pr merge               # Merge PR

# Issues
gh issue list             # List issues
gh issue view <num>       # View issue
gh issue create           # Create issue

# Workflow/Actions
gh run list               # List workflow runs
gh run view <id>          # View run details
gh run watch              # Watch running workflow
```

### Custom Alias

```yaml
aliases:
    co: pr checkout       # gh co <pr-num>
```

## SSH Configuration

### Key Location

```
~/.ssh/
├── id_ed25519           # Private key
├── id_ed25519.pub       # Public key
├── authorized_keys      # Allowed keys
├── known_hosts          # Known hosts
└── config               # SSH config
```

### SSH Config

**File:** `~/.ssh/config`

```bash
Host nas
    Hostname nas
    User tt
    IdentityFile ~/.ssh/id_ed25519

Host arch
    Hostname arch
    User tt
    IdentityFile ~/.ssh/id_ed25519

Host pve
    Hostname pve
    User root
    IdentityFile ~/.ssh/id_ed25519

Host kali
    Hostname kali
    User kali
    IdentityFile ~/.ssh/id_ed25519

Host debian
    Hostname debian
    User tt
    IdentityFile ~/.ssh/id_ed25519

Host pi
    Hostname pi
    User tt
    IdentityFile ~/.ssh/id_ed25519

Host pi2
    Hostname pi2
    User tt
    IdentityFile ~/.ssh/id_ed25519

Host *
    HashKnownHosts yes
    Compression yes
    SendEnv LANG LC_*
    RequestTTY yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
    ForwardAgent no
    AddKeysToAgent no
```

### Host Profiles

| Host | Hostname | User | Description |
|------|----------|------|-------------|
| nas | nas | tt | NAS server |
| arch | arch | tt | Arch Linux |
| pve | pve | root | Proxmox VE |
| kali | kali | kali | Kali Linux |
| debian | debian | tt | Debian server |
| rpi | pi | tt | Raspberry Pi |
| pi2 | pi2 | tt | Raspberry Pi 2 |

### Global Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| HashKnownHosts | yes | Security |
| Compression | yes | Performance |
| ServerAliveInterval | 30 | Keep alive |
| ServerAliveCountMax | 3 | Max retries |
| ForwardAgent | no | Security |

### SSH Commands

```bash
# Connect to host
ssh nas
ssh pve
ssh kali

# Copy file to remote
scp file.txt nas:~/

# Copy from remote
scp nas:~/file.txt ./

# Rsync
rsync -avz local/ nas:~/backup/

# SSH tunnel
ssh -L 8080:localhost:80 nas
```

### Key Management

```bash
# Generate new key
ssh-keygen -t ed25519 -C "comment"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host

# Check key fingerprint
ssh-keygen -lf ~/.ssh/id_ed25519.pub

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l
```

### SSH Agent

Auto-loaded on shell start (configured in zshrc):

```bash
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
if ! ssh-add -l &>/dev/null; then
    ssh-add ~/.ssh/id_ed25519
fi
```

## Integration

### Git over SSH

For GitHub SSH (alternative to HTTPS):

```bash
# Add to ~/.gitconfig
[url "git@github.com:"]
    insteadOf = https://github.com/

# Or clone with SSH
git clone git@github.com:user/repo.git
```

### GitHub CLI + Git

GitHub CLI handles authentication for git operations:

```bash
# Uses gh auth for git push/pull
git push origin main

# Clone via gh
gh repo clone user/repo
```

## Troubleshooting

### SSH Connection Refused

```bash
# Check if SSH service running on remote
systemctl status sshd

# Test connection verbosely
ssh -vvv host
```

### Git Authentication Failed

```bash
# Check GitHub CLI auth
gh auth status

# Re-authenticate
gh auth login
```

### SSH Key Not Found

```bash
# Check key exists
ls -la ~/.ssh/

# Check permissions
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh/
```

## Quick Reference

```bash
# Git
git status
git add .
git commit -m "message"
git push

# GitHub CLI
gh repo view --web
gh pr create
gh pr list

# SSH
ssh nas                   # Connect to host
scp file nas:~/           # Copy file
ssh-add -l                # List loaded keys

# Config locations
~/.gitconfig
~/.config/gh/config.yml
~/.ssh/config
```

## Related

- [07-SHELL](./07-SHELL.md) - Git aliases
- [03-NEOVIM](./03-NEOVIM.md) - Git integration in Neovim
