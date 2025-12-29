# 03 - Neovim

LazyVim distribution with LSP, completion, and modern IDE features.

## Overview

| Property | Value |
|----------|-------|
| Version | v0.11.5 |
| Distribution | LazyVim |
| Plugin Manager | lazy.nvim |
| Leader Key | Space |
| Colorscheme | Catppuccin (tokyonight available) |

## Installation

LazyVim installed via starter template:

```bash
# Backup and install
mv ~/.config/nvim{,.bak}
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
nvim  # Plugins auto-install
```

**Previous config backed up to:** `~/.config/nvim.bak`

## Configuration

**Directory:** `~/.config/nvim/`

```
nvim/
├── init.lua                 # Entry point (loads LazyVim)
├── lazyvim.json            # LazyVim extras config
├── lazy-lock.json          # Plugin version lock
├── stylua.toml             # Lua formatter config
└── lua/
    ├── config/
    │   ├── autocmds.lua    # Custom autocommands
    │   ├── keymaps.lua     # Custom keybindings
    │   ├── lazy.lua        # lazy.nvim bootstrap
    │   └── options.lua     # Editor options
    └── plugins/
        └── example.lua     # Custom plugins
```

## Plugins (Core)

### UI & Visual

| Plugin | Purpose |
|--------|---------|
| catppuccin/tokyonight | Color schemes |
| lualine.nvim | Status line |
| bufferline.nvim | Buffer tabs |
| snacks.nvim | Dashboard, notifications, terminal |
| noice.nvim | Enhanced UI for commands/messages |
| which-key.nvim | Keybinding hints |
| mini.icons | File icons |

### LSP & Completion

| Plugin | Purpose |
|--------|---------|
| nvim-lspconfig | LSP client |
| mason.nvim | LSP/formatter installer |
| mason-lspconfig.nvim | Mason + LSP integration |
| blink.cmp | Completion engine |
| lazydev.nvim | Lua development |

### Navigation & Search

| Plugin | Purpose |
|--------|---------|
| snacks.picker | Fuzzy finder (files, grep, buffers) |
| snacks.explorer | File explorer |
| flash.nvim | Quick navigation |
| grug-far.nvim | Search and replace |

### Syntax & Code

| Plugin | Purpose |
|--------|---------|
| nvim-treesitter | Syntax highlighting |
| nvim-treesitter-textobjects | Text objects |
| conform.nvim | Formatting |
| nvim-lint | Linting |
| todo-comments.nvim | TODO highlighting |
| mini.pairs | Auto pairs |
| mini.surround | Surround text objects |
| mini.ai | Enhanced text objects |

### Git

| Plugin | Purpose |
|--------|---------|
| gitsigns.nvim | Git signs in gutter |
| snacks.lazygit | Lazygit integration |

## Keybindings

### Leader Key: Space

Press `Space` to see all available keybindings via which-key.

### General

| Key | Action |
|-----|--------|
| `<leader>` | Show keybindings |
| `<leader>l` | Lazy plugin manager |
| `<leader>qq` | Quit all |
| `<C-s>` | Save file |

### Files & Buffers

| Key | Action |
|-----|--------|
| `<leader><space>` | Find files |
| `<leader>,` | Switch buffer |
| `<leader>e` | File explorer |
| `<leader>E` | File explorer (cwd) |
| `<leader>bd` | Delete buffer |
| `<leader>bo` | Delete other buffers |
| `<S-h>` | Previous buffer |
| `<S-l>` | Next buffer |

### Search (Picker)

| Key | Action |
|-----|--------|
| `<leader>/` | Grep (live search) |
| `<leader>:` | Command history |
| `<leader>ff` | Find files |
| `<leader>fr` | Recent files |
| `<leader>fg` | Find in git files |
| `<leader>fb` | Buffers |
| `<leader>sg` | Grep |
| `<leader>sw` | Word under cursor |
| `<leader>ss` | LSP symbols |
| `<leader>sS` | Workspace symbols |
| `<leader>sk` | Keymaps |
| `<leader>sh` | Help |
| `<leader>sm` | Marks |

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `gD` | Go to declaration |
| `K` | Hover documentation |
| `gK` | Signature help |
| `<leader>cl` | LSP info |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename |
| `<leader>cR` | Rename file |
| `<leader>cf` | Format |
| `]]` | Next reference |
| `[[` | Prev reference |

### Git

| Key | Action |
|-----|--------|
| `<leader>gg` | Lazygit |
| `<leader>gf` | Lazygit file history |
| `<leader>gl` | Lazygit log |
| `<leader>gb` | Git blame line |
| `<leader>gB` | Git browse |
| `]h` | Next hunk |
| `[h` | Previous hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghp` | Preview hunk |

### Windows

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Navigate windows |
| `<leader>-` | Split below |
| `<leader>\|` | Split right |
| `<leader>wd` | Delete window |
| `<leader>wm` | Maximize window |

### Terminal

| Key | Action |
|-----|--------|
| `<C-/>` | Toggle terminal |
| `<C-_>` | Toggle terminal (alt) |
| `<leader>ft` | Terminal (cwd) |
| `<leader>fT` | Terminal (root) |

### UI Toggles

| Key | Action |
|-----|--------|
| `<leader>uf` | Toggle format on save |
| `<leader>us` | Toggle spelling |
| `<leader>uw` | Toggle word wrap |
| `<leader>ul` | Toggle line numbers |
| `<leader>ud` | Toggle diagnostics |
| `<leader>uc` | Toggle conceal |
| `<leader>uC` | Toggle colorscheme |

### Diagnostics

| Key | Action |
|-----|--------|
| `<leader>xx` | Diagnostics (Trouble) |
| `<leader>xX` | Buffer diagnostics |
| `<leader>cs` | Symbols (Trouble) |
| `<leader>xL` | Location list |
| `<leader>xQ` | Quickfix list |
| `]d` | Next diagnostic |
| `[d` | Prev diagnostic |
| `]e` | Next error |
| `[e` | Prev error |
| `]w` | Next warning |
| `[w` | Prev warning |

## Mason - Language Servers

Open with `:Mason` or `<leader>cm`

### Installed

| Server | Language |
|--------|----------|
| lua-language-server | Lua |
| stylua | Lua formatter |
| shfmt | Shell formatter |

### Install More

```vim
:Mason              " Open Mason UI
:MasonInstall <pkg> " Install package
```

Common servers:
- `typescript-language-server` - TypeScript/JavaScript
- `pyright` - Python
- `rust-analyzer` - Rust
- `gopls` - Go
- `tailwindcss-language-server` - Tailwind CSS

## TreeSitter Parsers

Installed parsers:

```
bash, c, css, diff, html, javascript, json, lua,
markdown, markdown_inline, python, regex, scss,
toml, tsx, typescript, vim, vimdoc, xml, yaml
```

Install more with `:TSInstall <lang>`

## LazyVim Extras

Enable additional features in `~/.config/nvim/lazyvim.json`:

```json
{
  "extras": [
    "lazyvim.plugins.extras.lang.typescript",
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.go"
  ]
}
```

Or use `:LazyExtras` to browse and enable.

## Custom Configuration

### Add Plugins

Create `~/.config/nvim/lua/plugins/myplugins.lua`:

```lua
return {
  {
    "username/plugin-name",
    config = function()
      require("plugin-name").setup({})
    end,
  },
}
```

### Add Keybindings

Edit `~/.config/nvim/lua/config/keymaps.lua`:

```lua
vim.keymap.set("n", "<leader>xx", function()
  -- your code
end, { desc = "My custom keymap" })
```

### Change Options

Edit `~/.config/nvim/lua/config/options.lua`:

```lua
vim.opt.relativenumber = false
vim.opt.wrap = true
```

## Commands

```vim
:Lazy              " Plugin manager
:LazyHealth        " Health check
:LazyExtras        " Browse extras
:Mason             " LSP/tool installer
:TSInstall <lang>  " Install treesitter parser
:LspInfo           " LSP status
:checkhealth       " Full health check
```

## File Locations

| Path | Purpose |
|------|---------|
| `~/.config/nvim/` | Configuration |
| `~/.local/share/nvim/` | Plugin data, parsers |
| `~/.local/state/nvim/` | Logs, shada |
| `~/.cache/nvim/` | Cache |
| `~/.config/nvim.bak/` | Previous config backup |

## Troubleshooting

### Health Check

```vim
:LazyHealth       " LazyVim specific
:checkhealth      " Full Neovim health
```

### Reset Plugins

```bash
rm -rf ~/.local/share/nvim/lazy
nvim  # Plugins reinstall
```

### Reset Everything

```bash
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
nvim  # Fresh start
```

### LSP Not Working

```vim
:LspInfo          " Check if LSP attached
:Mason            " Install missing servers
:LspLog           " View LSP logs
```

## Quick Reference

```bash
# Launch
nvim
nvim file.txt
nvim .

# Config
~/.config/nvim/

# Key commands
Space           # Leader - show all keybindings
Space Space     # Find files
Space /         # Live grep
Space e         # File explorer
Space gg        # Lazygit
gd              # Go to definition
K               # Hover docs
```

## Related

- [04-EDITORS](./04-EDITORS.md) - VS Code
- [07-SHELL](./07-SHELL.md) - EDITOR variable
- [14-TMUX](./14-TMUX.md) - Terminal multiplexer
