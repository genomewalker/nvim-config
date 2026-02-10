-- Toggleterm - horizontal terminal at bottom
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-/>", "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal" },
    { "<C-/>", "<cmd>ToggleTerm<cr>", mode = "t", desc = "Toggle Terminal" },
  },
  opts = {
    size = function(term)
      if term.direction == "horizontal" then
        return vim.o.lines * 0.25  -- 25% of screen height
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    direction = "horizontal",
    open_mapping = [[<C-/>]],
    shade_terminals = false,
    start_in_insert = true,
    persist_size = true,
  },
}
