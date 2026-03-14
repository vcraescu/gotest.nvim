local M = {}

---@param lines string[]
---@return gotest.GoTestResult[]?
local function decode_lines(lines)
  assert(lines, "Expected non-nil lines")

  ---@type gotest.GoTestResult[]
  local out = {}

  for _, line in ipairs(lines) do
    local ok, decoded = pcall(vim.fn.json_decode, line)
    if not ok then
      return nil
    end

    table.insert(out, decoded)
  end

  return out
end

---@param lines string[]
---@return gotest.GoTestResult[]
function M.parse_results(lines)
  assert(lines, "Expected non-nil lines")

  local results = decode_lines(lines) or {}

  for _, result in ipairs(results) do
    if result.Output then
      result.Output = vim.fn.trim(result.Output, "\n", 2)
    end
  end

  return results
end

return M
