# Contributing to Arch Linux Handbook

Thank you for your interest in contributing! This project welcomes improvements, corrections, and additions.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report errors, outdated information, or suggest improvements
- Include the document path and section when reporting issues
- For command errors, include the error message and your system details

### Submitting Changes

1. **Fork** the repository
2. **Create a branch** for your changes:
   ```bash
   git checkout -b fix/typo-in-installation
   ```
3. **Make your changes** following the style guidelines below
4. **Test** any commands or scripts you modify
5. **Commit** with a clear message:
   ```bash
   git commit -m "Fix: correct mount options in 03-BASE-INSTALL"
   ```
6. **Push** and create a Pull Request

### Style Guidelines

#### Document Structure

- Use numbered prefixes for ordering: `01-OVERVIEW.md`, `02-SETUP.md`
- Start each document with a level-1 heading (`# Title`)
- Include a brief description after the title

#### Formatting

- Use fenced code blocks with language hints:
  ~~~markdown
  ```bash
  sudo pacman -S package
  ```
  ~~~
- Use tables for structured information
- Use `<placeholder>` for values users must replace
- Keep lines under 100 characters where practical

#### Commands

- Prefix commands requiring root with `sudo`
- Include expected output where helpful
- Add comments for complex commands:
  ```bash
  # Enable and start the service
  sudo systemctl enable --now service.service
  ```

#### Placeholders

Use descriptive placeholders that users should replace:

| Placeholder | Meaning |
|-------------|---------|
| `<LUKS-UUID>` | LUKS partition UUID |
| `<EFI-UUID>` | EFI partition UUID |
| `<username>` | Your username |
| `100.x.x.x` | Tailscale IP address |

### What We're Looking For

- **Corrections**: Fix errors, typos, outdated commands
- **Clarifications**: Improve unclear explanations
- **Additions**: New guides that fit the scope (Arch Linux, Hyprland, related tools)
- **Updates**: Keep pace with upstream changes

### Scope

This handbook focuses on:

- Arch Linux installation and configuration
- Btrfs + LUKS encryption setups
- Hyprland/Wayland desktop environment
- System recovery and maintenance
- Virtualization (KVM/QEMU)
- Docker containers
- ThinkPad hardware optimization

Out of scope:

- Other distributions (Ubuntu, Fedora, etc.)
- Other desktop environments (GNOME, KDE, etc.)
- Non-Linux systems

## Code of Conduct

- Be respectful and constructive
- Focus on the content, not the person
- Help others learn

## License

By contributing, you agree that your contributions will be licensed under [CC BY-SA 4.0](LICENSE).
