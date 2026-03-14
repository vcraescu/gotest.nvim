local M = {}

--- @param lines string[]
--- @return gotest.GoTestResult[]?
local function json_decode_lines(lines)
  assert(lines, "Expected non-nil lines")

  --- @type gotest.GoTestResult[]
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

--- @param lines string[]
--- @return gotest.Parser
function M.new(lines)
  assert(lines, "Expected non-nil lines")

  return setmetatable({ _lines = lines }, { __index = M })
end

--- @return gotest.GoTestResult[]
function M:parse_results()
  if self._results then
    return self._results
  end

  --- @type gotest.GoTestResult[]?
  self._results = json_decode_lines(self._lines)

  if not self._results or #self._results == 0 then
    self._results = {}

    for i, line in ipairs(self._lines) do
      local decoded_line = json_decode_lines({ line })
      if decoded_line then
        self._results[i] = decoded_line[0]
      else
        self._results[i] = { Output = line }
      end
    end
  end

  for i, result in ipairs(self._results) do
    if result.Output then
      self._results[i].Output = vim.fn.trim(result.Output, "\n", 2)
    end
  end

  return self._results
end

return M
