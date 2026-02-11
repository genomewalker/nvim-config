-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Mouse: enabled in normal/visual/insert but NOT terminal mode
-- This allows normal text selection in terminals without needing Shift
vim.opt.mouse = "nvi"

-- OSC 52 clipboard - copies to local clipboard over SSH (Ghostty supports this)
vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}

-- Terminal improvements
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    -- No line numbers in terminals
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    -- No sign column
    vim.opt_local.signcolumn = "no"
    -- Start in insert mode
    vim.cmd("startinsert")
  end,
})

-- Easy escape from terminal mode: Esc Esc (double tap)
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Quick paste in terminal mode (Ctrl+Shift+V)
vim.keymap.set("t", "<C-S-v>", function()
  local keys = vim.api.nvim_replace_termcodes('<C-\\><C-n>"+pi', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = "Paste in terminal" })
