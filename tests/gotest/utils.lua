local M = {}

local fixtures_path = "./tests/gotest/fixtures/"

function M.load_fixture(filename)
  return vim.fn.readfile(fixtures_path .. filename)
end

function M.load_buf_fixture(filename, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, M.load_fixture(filename))
  vim.bo[bufnr].filetype = filetype
  vim.api.nvim_set_current_buf(bufnr)

  return bufnr
end

function M.setup_test()
  vim.cmd("packadd plenary.nvim")
  vim.cmd("packadd nvim-treesitter")

  require("nvim-treesitter.install").update({ with_sync = true })
  require("nvim-treesitter.install").ensure_installed("go") -- Ensure 'go' parser is installed
  require("nvim-treesitter.configs").setup({
    ensure_installed = { "go" },
    highlight = { enable = true },
    auto_install = true,
  })

  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok or not parsers.has_parser("go") then
    print("Go treesitter parser is not installed")
  end
end

return M
