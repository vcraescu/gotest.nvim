local M = {}

local fixtures_path = "./tests/gotest/fixtures/"

function M.load_fixture(name)
  return vim.fn.readfile(fixtures_path .. name)
end

return M
