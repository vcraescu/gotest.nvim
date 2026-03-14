vim.opt.runtimepath:prepend(vim.fn.getcwd())

vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
}, {
  load = true,
  confirm = false,
})
