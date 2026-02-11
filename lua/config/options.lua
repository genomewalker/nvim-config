-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Mouse: enabled by default
vim.opt.mouse = "a"

-- OSC 52 clipboard - copies to local clipboard over SSH
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

-- =============================================================================
-- Terminal Workflow:
--   - In terminal: mouse OFF (can select text)
--   - Press Esc: exits to normal mode, mouse ON (can click)
--   - Press 'i' to go back to terminal insert mode
-- =============================================================================

-- Disable mouse when entering ANY terminal buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "term://*",
  callback = function()
    vim.opt.mouse = ""
  end,
})

-- Enable mouse when leaving terminal buffer
vim.api.nvim_create_autocmd("BufLeave", {
  pattern = "term://*",
  callback = function()
    vim.opt.mouse = "a"
  end,
})

-- Single Esc exits terminal mode AND re-enables mouse
vim.keymap.set("t", "<Esc>", function()
  vim.opt.mouse = "a"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
end, { desc = "Exit terminal mode" })

-- When entering insert mode in terminal, disable mouse again
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:t",
  callback = function()
    vim.opt.mouse = ""
  end,
})

-- Terminal buffer settings
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Quick paste in terminal mode
vim.keymap.set("t", "<C-S-v>", function()
  local keys = vim.api.nvim_replace_termcodes('<C-\\><C-n>"+pi', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = "Paste in terminal" })
