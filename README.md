# Neovim Config

LazyVim-based config with Claude Code integration via [prism.nvim](https://github.com/genomewalker/prism.nvim).

## Quick Install

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone this repo
git clone https://github.com/genomewalker/nvim-config.git ~/.config/nvim

# Install prism.nvim for Claude Code integration
# (Run this in Claude Code terminal)
/prism install
```

## What's Included

- **LazyVim** - Modern Neovim setup with sensible defaults
- **Prism.nvim** - Claude Code integration with 55+ MCP tools
- **Diffview** - Enhanced git diff viewer
- **Socket registry** - Multi-instance Neovim support

## Keybindings

### Claude Code (via Prism)

| Key | Action |
|-----|--------|
| `Ctrl+\` | Toggle Claude terminal |
| `Ctrl+\ Ctrl+\` | Exit terminal mode (passthrough) |
| `<leader>cc` | Open Prism layout |
| `<leader>ct` | Toggle terminal |
| `<leader>cs` | Send selection to Claude |
| `<leader>ca` | Code actions |
| `<leader>cd` | Show diff |
| `<leader>cm` | Switch model |

### Git (via Diffview)

| Key | Action |
|-----|--------|
| `<leader>gd` | Git diff view |
| `<leader>gh` | File history |
| `<leader>gH` | Repo history |

## Structure

```
~/.config/nvim/
├── init.lua                 # Entry point
├── lua/
│   ├── config/
│   │   ├── lazy.lua         # Plugin manager setup
│   │   ├── options.lua      # Vim options
│   │   ├── keymaps.lua      # Key bindings
│   │   └── autocmds.lua     # Auto commands
│   ├── plugins/
│   │   └── prism.lua        # Prism.nvim config
│   └── claude/
│       └── init.lua         # Claude Code harness
└── after/plugin/
    └── prism-socket.lua     # Socket registry for MCP
```

## Requirements

- Neovim >= 0.9
- Git
- Python 3 with msgpack (`pip install msgpack`)
- [Claude Code](https://claude.com/claude-code)

## Updating

```bash
cd ~/.config/nvim
git pull
```

Then restart Neovim to apply changes.
