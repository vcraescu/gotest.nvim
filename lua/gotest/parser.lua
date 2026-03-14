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
---@return gotest.Parser
function M.new(lines)
  assert(lines, "Expected non-nil lines")

  return setmetatable({ _lines = lines }, { __index = M })
end

---@return gotest.GoTestResult[]
function M:parse_results()
  if self._results then
    return self._results
  end

  self._results = decode_lines(self._lines) or {}

  for _, result in ipairs(self._results) do
    if result.Output then
      result.Output = vim.fn.trim(result.Output, "\n", 2)
    end
  end

  return self._results
end

return M
