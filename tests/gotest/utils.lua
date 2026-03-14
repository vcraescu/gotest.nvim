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
end

return M
