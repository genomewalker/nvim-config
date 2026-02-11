-- R Development for Neovim
-- Minimal config that doesn't interfere with prism.nvim

-- Create R layout (global for command access)
_G.create_rstudio_layout = function()
  local editor_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
    local bufname = vim.api.nvim_buf_get_name(buf)
    if not (bufname:match("^prism://") or buftype == "terminal") then
      editor_win = win
      break
    end
  end

  if not editor_win then
    vim.notify("No editor window found", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_set_current_win(editor_win)
  vim.cmd("belowright split")
  vim.api.nvim_win_set_height(0, 20)
  vim.cmd("terminal /maps/projects/fernandezguerra/apps/opt/conda/envs/r/bin/radian")
  vim.g.radian_buf = vim.api.nvim_get_current_buf()

  vim.defer_fn(function()
    local chan = vim.b[vim.g.radian_buf].terminal_job_id
    if chan then
      vim.fn.chansend(chan, 'source("~/.local/share/R/inline_plots.R")\n')
    end
  end, 1500)

  vim.api.nvim_set_current_win(editor_win)
  vim.notify("R layout activated", vim.log.levels.INFO)
end

-- Send to radian helpers
local function get_radian_channel()
  if vim.g.radian_buf and vim.api.nvim_buf_is_valid(vim.g.radian_buf) then
    local ok, chan = pcall(vim.api.nvim_buf_get_var, vim.g.radian_buf, "terminal_job_id")
    if ok and chan then return chan end
  end
  return nil
end

_G.send_to_radian = function(text)
  local chan = get_radian_channel()
  if chan then
    vim.fn.chansend(chan, "\027[200~" .. text .. "\027[201~\n")
  else
    vim.notify("Radian not found. Use \\rL to start", vim.log.levels.WARN)
  end
end

_G.send_line_to_radian = function()
  send_to_radian(vim.api.nvim_get_current_line())
  vim.cmd("normal! j")
end

return {
  {
    "R-nvim/R.nvim",
    ft = { "r", "rmd", "quarto", "rnoweb", "rhelp" },
    config = function()
      require("r").setup({
        R_path = "/maps/projects/fernandezguerra/apps/opt/conda/envs/r/bin",
        R_app = "radian",
        R_cmd = "radian",
        bracketed_paste = true,
        open_pdf = "no",
        open_html = "no",
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "r", "rmd", "quarto" },
        callback = function()
          vim.keymap.set("n", "<leader>rL", create_rstudio_layout, { buffer = true, desc = "R layout" })
          vim.keymap.set("n", "<leader>rl", send_line_to_radian, { buffer = true, desc = "Send line" })
          vim.keymap.set("n", "<CR>", send_line_to_radian, { buffer = true })
        end,
      })
    end,
  },
}
