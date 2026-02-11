-- Persistent terminal below edit buffer
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  lazy = false,
  config = function()
    require("toggleterm").setup({
      open_mapping = false,
      shade_terminals = false,
      persist_size = true,
      persist_mode = true,
    })

    local term_buf = nil
    local term_win = nil
    local term_height = math.floor(vim.o.lines * 0.25)

    -- Find the main edit window (non-terminal, non-special)
    local function find_edit_window()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        local bt = vim.bo[buf].buftype
        local name = vim.api.nvim_buf_get_name(buf)
        if bt == "" and not name:match("prism://") then
          return win
        end
      end
      return nil
    end

    local function open_term()
      if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_set_current_win(term_win)
        vim.cmd("startinsert")
        return
      end

      local edit_win = find_edit_window()
      if not edit_win then
        -- No edit window, just create a split from current
        vim.cmd("below " .. term_height .. "split")
      else
        vim.api.nvim_set_current_win(edit_win)
        vim.cmd("below " .. term_height .. "split")
      end

      term_win = vim.api.nvim_get_current_win()

      -- Reuse existing terminal buffer or create new
      if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        vim.api.nvim_win_set_buf(term_win, term_buf)
      else
        vim.cmd("terminal")
        term_buf = vim.api.nvim_get_current_buf()
        -- Name it for easy identification
        vim.api.nvim_buf_set_name(term_buf, "term://toggleterm")
      end

      -- Window settings
      vim.wo[term_win].winfixheight = true
      vim.wo[term_win].number = false
      vim.wo[term_win].relativenumber = false
      vim.wo[term_win].signcolumn = "no"

      -- Buffer settings
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
        -- If we're in the terminal, close it
        if vim.api.nvim_get_current_win() == term_win then
          close_term()
        else
          -- Focus the terminal
          vim.api.nvim_set_current_win(term_win)
          vim.cmd("startinsert")
        end
      else
        open_term()
      end
    end

    -- Keymaps (work in normal and terminal mode)
    vim.keymap.set({ "n", "t" }, "<C-_>", toggle_term, { desc = "Toggle Terminal" })
    vim.keymap.set({ "n", "t" }, "<C-/>", toggle_term, { desc = "Toggle Terminal" })
    vim.keymap.set("n", "<leader>tt", toggle_term, { desc = "Toggle Terminal" })

    -- Auto-open on startup
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.defer_fn(open_term, 100)
      end,
    })

    -- Prevent terminal from being accidentally quit
    vim.api.nvim_create_autocmd("TermClose", {
      callback = function(args)
        if args.buf == term_buf then
          term_buf = nil
          term_win = nil
        end
      end,
    })
  end,
}
