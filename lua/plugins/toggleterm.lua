-- Toggleterm - horizontal terminal below edit buffer (not over Claude)
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    {
      "<C-/>",
      function()
        -- Find a non-terminal, non-prism window to split
        local wins = vim.api.nvim_tabpage_list_wins(0)
        for _, win in ipairs(wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          local buftype = vim.bo[buf].buftype
          local bufname = vim.api.nvim_buf_get_name(buf)
          -- Skip terminal buffers and prism buffer
          if buftype ~= "terminal" and not bufname:match("prism://") then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
        vim.cmd("ToggleTerm")
      end,
      desc = "Toggle Terminal",
    },
    { "<C-/>", "<cmd>ToggleTerm<cr>", mode = "t", desc = "Toggle Terminal" },
  },
  opts = {
    size = function(term)
      if term.direction == "horizontal" then
        return vim.o.lines * 0.25
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    direction = "horizontal",
    shade_terminals = false,
    start_in_insert = true,
    persist_size = true,
  },
}
