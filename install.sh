#!/bin/bash
# Neovim config installer

set -e

NVIM_CONFIG="$HOME/.config/nvim"
REPO_URL="https://github.com/genomewalker/nvim-config.git"

echo "╔═══════════════════════════════════════╗"
echo "║       Neovim Config Installer         ║"
echo "╚═══════════════════════════════════════╝"
echo

# Check for existing config
if [ -d "$NVIM_CONFIG" ]; then
  if [ -d "$NVIM_CONFIG/.git" ]; then
    echo "[!] Existing nvim config is a git repo."
    echo "    Updating instead of replacing..."
    cd "$NVIM_CONFIG"
    git pull
    echo "[+] Updated!"
    exit 0
  else
    echo "[!] Existing config found at $NVIM_CONFIG"
    read -p "    Backup and replace? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      BACKUP="$NVIM_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
      mv "$NVIM_CONFIG" "$BACKUP"
      echo "[+] Backed up to $BACKUP"
    else
      echo "[!] Aborted."
      exit 1
    fi
  fi
fi

# Clone the repo
echo "[+] Cloning nvim-config..."
git clone "$REPO_URL" "$NVIM_CONFIG"

echo
echo "╔═══════════════════════════════════════╗"
echo "║         Installation Complete!        ║"
echo "╚═══════════════════════════════════════╝"
echo
echo "Next steps:"
echo "  1. Open Neovim - plugins will auto-install"
echo "  2. In Claude Code, run: /prism install"
echo "  3. Restart Claude Code to load MCP server"
echo
