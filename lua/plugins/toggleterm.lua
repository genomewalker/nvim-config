-- Persistent terminal below edit buffer (like Claude terminal)
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  lazy = false,
  config = function()
    require("toggleterm").setup({ open_mapping = false })

    local term_buf = nil
    local term_win = nil

    local function open_term()
      if term_win and vim.api.nvim_win_is_valid(term_win) then
        return -- Already open
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

      if not edit_win then return end
      vim.api.nvim_set_current_win(edit_win)

      -- Create split below edit window
      local height = math.floor(vim.o.lines * 0.25)
      vim.cmd("below " .. height .. "split")
      term_win = vim.api.nvim_get_current_win()

      -- Create or reuse terminal buffer
      if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        vim.api.nvim_win_set_buf(term_win, term_buf)
      else
        vim.cmd("terminal")
        term_buf = vim.api.nvim_get_current_buf()
      end

      -- Make window persistent (like Claude terminal)
      vim.wo[term_win].winfixheight = true
      vim.bo[term_buf].buflisted = false

      vim.cmd("startinsert")
    end

    local function close_term()
      if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_hide(term_win)
        term_win = nil
      end
    end

    local function toggle_term()
      if term_win and vim.api.nvim_win_is_valid(term_win) then
        close_term()
      else
        open_term()
      end
    end

    -- Keymaps
    vim.keymap.set({ "n", "t" }, "<C-_>", toggle_term, { desc = "Toggle Terminal" })
    vim.keymap.set({ "n", "t" }, "<C-/>", toggle_term, { desc = "Toggle Terminal" })
    vim.keymap.set("n", "<leader>tt", toggle_term, { desc = "Toggle Terminal" })

    -- Auto-open on startup (after UI is ready)
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.defer_fn(open_term, 100)
      end,
    })

    -- Restore terminal if accidentally closed by buffer operations
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
          -- Check if terminal window still exists
          if not term_win or not vim.api.nvim_win_is_valid(term_win) then
            -- Terminal buffer exists but window gone - could reopen here
            -- For now, just clear the reference
            term_win = nil
          end
        end
      end,
    })
  end,
}

