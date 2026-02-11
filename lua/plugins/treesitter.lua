-- Override treesitter to compile parsers locally (glibc 2.28 compatibility)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Force local compilation instead of prebuilt binaries
      require("nvim-treesitter.install").compilers = { "gcc", "cc", "clang" }
      require("nvim-treesitter.install").prefer_git = false

      return opts
    end,
  },
}
