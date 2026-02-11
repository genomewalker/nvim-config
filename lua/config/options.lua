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
-- Terminal Mouse Workflow:
--   1. In terminal INSERT mode (typing): mouse OFF → can select text with mouse
--   2. Press Esc → terminal NORMAL mode: mouse ON → can click to switch windows
--   3. Click where you want → press 'i' to type in terminal again
-- =============================================================================

-- Entering terminal insert mode → disable mouse (allows text selection)
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:t",
  callback = function()
    vim.opt.mouse = ""
  end,
})

-- Leaving terminal insert mode → enable mouse (allows clicking to switch)
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "t:*",
  callback = function()
    vim.opt.mouse = "a"
  end,
})

-- Terminal buffer settings
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})

-- Easy escape from terminal: Esc goes to terminal normal mode
-- (default behavior, but being explicit)
-- Double Esc exits to normal buffer if needed
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Quick paste in terminal mode
vim.keymap.set("t", "<C-S-v>", function()
  local keys = vim.api.nvim_replace_termcodes('<C-\\><C-n>"+pi', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = "Paste in terminal" })
