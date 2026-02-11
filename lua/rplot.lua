-- rplot.lua: Display R plots in Neovim floating terminal windows

local M = {}

M.config = {
  plot_file = vim.fn.expand("~/.local/share/R/last_plot.png"),
  width = 80,
  height = 40,
  chafa = "/maps/projects/fernandezguerra/apps/opt/conda/envs/bioinfo/bin/chafa",
}

function M.show_plot(opts)
  opts = opts or {}
  local path = opts.path or M.config.plot_file
  local width = opts.width or M.config.width
  local height = opts.height or M.config.height

  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("Plot file not found: " .. path, vim.log.levels.WARN)
    return
  end

  local win_width = width + 4
  local win_height = height + 2
  local row = math.floor((vim.o.lines - win_height) / 2)
  local col = math.floor((vim.o.columns - win_width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  -- Mark buffer to prevent prism passthrough
  vim.b[buf].prism_terminal = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " R Plot (q to close) ",
    title_pos = "center",
  })

  -- Run chafa in terminal buffer
  local cmd = string.format("%s --size %dx%d %s", M.config.chafa, width, height, vim.fn.shellescape(path))

  vim.fn.termopen({"bash", "-c", cmd}, {
    on_exit = function() end, -- Don't auto-close
  })

  -- Close function
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  -- After chafa renders, switch to normal mode and set keymaps
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.cmd("stopinsert")
      vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
      vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
      vim.keymap.set("n", "<CR>", close, { buffer = buf, nowait = true })
    end
  end, 200)

  return win, buf
end

function M.watch_plots()
  local last_mtime = 0
  local timer = vim.loop.new_timer()

  timer:start(1000, 1000, vim.schedule_wrap(function()
    local stat = vim.loop.fs_stat(M.config.plot_file)
    if stat and stat.mtime.sec > last_mtime then
      last_mtime = stat.mtime.sec
      M.show_plot()
    end
  end))

  vim.notify("Watching for R plots... (:RPlotStop to stop)", vim.log.levels.INFO)
  M._timer = timer
end

function M.stop_watch()
  if M._timer then
    M._timer:stop()
    M._timer:close()
    M._timer = nil
    vim.notify("Stopped watching", vim.log.levels.INFO)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.api.nvim_create_user_command("RPlot", function() M.show_plot() end, {})
  vim.api.nvim_create_user_command("RPlotWatch", function() M.watch_plots() end, {})
  vim.api.nvim_create_user_command("RPlotStop", function() M.stop_watch() end, {})
end

return M
