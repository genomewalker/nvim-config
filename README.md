# Neovim Config

LazyVim-based config optimized for **vibe coding** with Claude Code via [prism.nvim](https://github.com/genomewalker/prism.nvim).

[![prism.nvim](https://img.shields.io/badge/Powered%20by-prism.nvim-orange)](https://github.com/genomewalker/prism.nvim)
[![LazyVim](https://img.shields.io/badge/Based%20on-LazyVim-blue)](https://lazyvim.org)

## Quick Install

```bash
# One-liner install
curl -fsSL https://raw.githubusercontent.com/genomewalker/nvim-config/main/install.sh | bash
```

Or manually:

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone this repo
git clone https://github.com/genomewalker/nvim-config.git ~/.config/nvim

# Open Neovim (plugins auto-install)
nvim

# In Claude Code, install prism.nvim
/prism install
```

## What's Included

### Core
- **[LazyVim](https://lazyvim.org)** - Modern Neovim with sensible defaults
- **[Prism.nvim](https://github.com/genomewalker/prism.nvim)** - Claude Code integration (65+ MCP tools)

### Productivity Plugins
- **[Harpoon2](https://github.com/ThePrimeagen/harpoon)** - Quick file switching (pin files, jump instantly)
- **[Trouble.nvim](https://github.com/folke/trouble.nvim)** - Better diagnostics panel
- **[Todo-comments](https://github.com/folke/todo-comments.nvim)** - Highlight & search TODOs
- **[Spectre](https://github.com/nvim-pack/nvim-spectre)** - Project-wide search & replace
- **[Diffview](https://github.com/sindrets/diffview.nvim)** - Enhanced git diffs

### UI Enhancements
- **Mini-indentscope** - Visual indent guides
- **Mini-surround** - Quick surround editing

## Keybindings

### Claude Code (Prism)

| Key | Action |
|-----|--------|
| `Ctrl+\` | Toggle Claude terminal |
| `Ctrl+\ Ctrl+\` | Exit terminal mode (passthrough) |
| `<leader>cc` | Open Prism layout |
| `<leader>ct` | Toggle terminal |
| `<leader>cs` | Send selection to Claude |
| `<leader>ca` | Code actions |

### Harpoon (Quick Files)

| Key | Action |
|-----|--------|
| `<leader>a` | Add file to harpoon |
| `Ctrl+e` | Show harpoon menu |
| `<leader>1-4` | Jump to file 1-4 |

### Diagnostics & Todos

| Key | Action |
|-----|--------|
| `<leader>xx` | Toggle Trouble (diagnostics) |
| `<leader>xt` | Show all TODOs |
| `<leader>st` | Search TODOs (Telescope) |
| `]t` / `[t` | Next/prev TODO |

### Search & Replace

| Key | Action |
|-----|--------|
| `<leader>sr` | Open Spectre (project replace) |
| `<leader>sw` | Replace word under cursor |

### Git

| Key | Action |
|-----|--------|
| `<leader>gd` | Git diff view |
| `<leader>gh` | File history |
| `<leader>gH` | Repo history |

## Talk to Claude

With prism.nvim, just tell Claude what you want:

```
"pin this file"           → harpoon_add
"show pinned files"       → harpoon_list
"go to harpoon 2"         → harpoon_goto(2)
"show trouble"            → trouble_toggle
"find todos"              → search_todos
"next todo"               → next_todo
"replace this everywhere" → spectre_word
```

## Structure

```
~/.config/nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── lazy.lua           # Plugin manager + LazyVim extras
│   │   ├── options.lua
│   │   ├── keymaps.lua
│   │   └── autocmds.lua
│   ├── plugins/
│   │   ├── prism.lua          # Claude Code integration
│   │   └── productivity.lua   # Harpoon, Trouble, Spectre, etc.
│   └── claude/
│       └── init.lua           # Claude terminal harness
└── after/plugin/
    └── prism-socket.lua       # Multi-instance socket registry
```

## Requirements

- Neovim >= 0.9
- Git
- Python 3 + msgpack (`pip install msgpack`)
- [Nerd Font](https://www.nerdfonts.com/) (for icons)
- [Claude Code](https://claude.ai/code)

## Updating

```bash
cd ~/.config/nvim && git pull
```

Then restart Neovim. Run `/prism update` in Claude Code if prism.nvim has updates.

## License

MIT
