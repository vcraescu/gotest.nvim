local Ts = require("gotest.ts")

---@class gotest.TestFile
---@field bufnr number?
local M = {
  bufnr = nil,
}

---@param bufnr number
---@return gotest.TestFile
function M.new(bufnr)
  assert(bufnr and bufnr >= 0, "bufnr must be a valid buffer number")

  return setmetatable({ bufnr = bufnr }, { __index = M })
end

---@return string?
function M:get_dir()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.bufnr), ":.:h")
end

---@return boolean
function M:is_test()
  local name = vim.api.nvim_buf_get_name(self.bufnr)

  return vim.endswith(name, "_test.go")
end

---@return string[]?, string? test name and table test name or sub test name
function M:get_current_test()
  local test_name = Ts.get_current_test_func_name(self.bufnr)
  if not test_name then
    return Ts.get_test_func_names(self.bufnr)
  end

  local table_test_name = Ts.get_current_table_test_name(self.bufnr)
  if table_test_name then
    return { test_name }, table_test_name
  end

  local sub_test_name = Ts.get_current_sub_test_name(self.bufnr)

  return { test_name }, sub_test_name
end

return M
