local ts = require("gotest.ts")
local M = {}

---@param bufnr integer
---@return string[]?, string? test name and table test name or sub test name
function M.get_current_test(bufnr)
  assert(bufnr and bufnr >= 0, "bufnr must be a valid buffer number")

  local test_name = ts.get_current_test_func_name(bufnr)
  if not test_name then
    return ts.get_test_func_names(bufnr)
  end

  local table_test_name = ts.get_current_table_test_name(bufnr)
  if table_test_name then
    return { test_name }, table_test_name
  end

  local sub_test_name = ts.get_current_sub_test_name(bufnr)

  return { test_name }, sub_test_name
end

return M
