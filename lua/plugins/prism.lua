-- Prism.nvim - Claude Code Integration
-- Requires: /prism install (installs to ~/.local/share/prism.nvim)

return {
  {
    dir = vim.fn.expand("~/.local/share/prism.nvim"),
    name = "prism.nvim",
    lazy = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("prism").setup({
        mcp = { auto_start = false },
        terminal = {
          provider = "native",
          position = "horizontal",
          height = 0.5,
          auto_start = true,
          passthrough = true,
        },
        claude = {
          model = nil,
          continue_session = false,
        },
        trust = { mode = "companion" },
      })
    end,
    keys = {
      { "<leader>cc", "<cmd>Prism<cr>", desc = "Prism: Open Layout" },
      { "<leader>ct", "<cmd>PrismToggle<cr>", desc = "Prism: Toggle Terminal" },
      { "<leader>cs", "<cmd>PrismSend<cr>", mode = { "n", "v" }, desc = "Prism: Send to Claude" },
      { "<leader>ca", "<cmd>PrismAction<cr>", mode = { "n", "v" }, desc = "Prism: Code Actions" },
      { "<leader>cd", "<cmd>PrismDiff<cr>", desc = "Prism: Show Diff" },
      { "<leader>cm", "<cmd>PrismModel<cr>", desc = "Prism: Switch Model" },
      { "<C-\\>", "<cmd>PrismToggle<cr>", desc = "Toggle Prism Terminal" },
    },
  },
}
