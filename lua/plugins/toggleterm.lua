-- Simple terminal below edit buffer (native vim split, respects columns)
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  lazy = false,  -- Load immediately
  config = function()
    local term_buf = nil
    local term_win = nil

    local function toggle_term()
      -- If terminal window exists and is valid, toggle it
      if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_hide(term_win)
        term_win = nil
        return
      end

      -- Find edit window (non-terminal, non-prism)
      local edit_win = nil
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        local bt = vim.bo[buf].buftype
        local name = vim.api.nvim_buf_get_name(buf)
        if bt ~= "terminal" and not name:match("prism://") then
          edit_win = win
          break
        end
      end

      if edit_win then
        vim.api.nvim_set_current_win(edit_win)
      end

      -- Create split below current window (respects column)
      local height = math.floor(vim.o.lines * 0.25)
      vim.cmd("belowright " .. height .. "split")
      term_win = vim.api.nvim_get_current_win()

      -- Reuse or create terminal buffer
      if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        vim.api.nvim_win_set_buf(term_win, term_buf)
      else
        vim.cmd("terminal")
        term_buf = vim.api.nvim_get_current_buf()
      end
      vim.cmd("startinsert")
    end

    vim.keymap.set({ "n", "t" }, "<C-/>", toggle_term, { desc = "Toggle Terminal" })
  end,
}
