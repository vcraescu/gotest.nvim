--- @class gotest.Parser
--- @field _tests gotest.GoTestNode[]?
--- @field _lines string[]?
--- @field _results gotest.GoTestResult[]
local M = {}

--- @class gotest.GoTestResult.Action
--- @field PASS string
--- @field SKIP string
--- @field FAIL string
--- @field BUILD_FAIL string
local GoTestResultAction = {
  PASS = "pass",
  SKIP = "skip",
  FAIL = "fail",
  BUILD_FAIL = "build-fail",
}

--- @class gotest.GoTestResult
--- @field Action? string
--- @field Package? string
--- @field Test? string
--- @field Output string

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

--- @param tests table
--- @param module_name string
--- @param test_name string
local function get_test_parent(tests, module_name, test_name)
  assert(tests, "Expected non-nil tests")
  assert(module_name, "Expected non-nil module_name")
  assert(test_name, "Expected non-nil test_name")

  for test in pairs(tests[module_name] or {}) do
    if vim.startswith(test_name, test .. "/") then
      return test
    end
  end

  return nil
end

--- @param test_name string
--- @param parent string
--- @return string
local function get_subtest_name(test_name, parent)
  assert(test_name, "Expected non-nil test_name")
  assert(parent, "Expected non-nil parent")

  local output, _ = string.gsub(test_name, parent .. "/", "")

  return output
end

--- @param test_name string
--- @param parent string
--- @return string
local function get_subtest_real_name(test_name, parent)
  test_name, _ = string.gsub(get_subtest_name(test_name, parent), "_", " ")

  return test_name
end

--- @param lines string[]
--- @return string?
--- @return number?
--- @return string[]
local function parse_failed_output(lines)
  if not lines or #lines <= 3 then
    return nil, nil, lines
  end

  local file, lineno
  local file_pattern = [[Error Trace:(.*)]]
  local file_and_lineno = string.match(lines[2], file_pattern)

  if file_and_lineno then
    file, lineno = unpack(vim.fn.split(file_and_lineno, ":"))
    assert(file, "Expected non-nil file")
    assert(lineno, "Expected non-nil lineno")

    file = vim.fn.trim(file)
    lineno = tonumber(vim.fn.trim(lineno), 10)
  end

  lines = vim.list_slice(lines, 2, #lines - 1)

  return file, lineno, lines
end

local function cmp(a, b)
  if a == b then
    return 0
  end

  return (a < b and -1) or 1
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

--- @class gotest.GoTestNode
--- @field module? string
--- @field name? string
--- @field real_name string?
--- @field failed? boolean
--- @field skipped? boolean
--- @field passed? boolean
--- @field ignore? boolean
--- @field file string?
--- @field lineno number?
--- @field output string[]
--- @field tests? gotest.GoTestNode[]

--- @return gotest.GoTestNode[]?
function M:parse()
  if self._tests then
    return self._tests
  end

  local all_test_names = {}
  local tests = {}
  local results = self:parse_results()

  for _, line in ipairs(results) do
    if line.Test then
      all_test_names[line.Package] = all_test_names[line.Package] or {}
      all_test_names[line.Package][line.Test] = true
    end
  end

  if vim.fn.empty(all_test_names) == 1 then
    return vim.fn.map(results, function(_, line)
      local output = line.Output and vim.fn.trim(line.Output, "\n ", 2)

      return {
        output = { output },
      }
    end)
  end

  for _, line in ipairs(results) do
    if line.Test then
      tests[line.Package] = tests[line.Package] or {}

      local parent = get_test_parent(all_test_names, line.Package, line.Test)
      local test = {
        name = line.Test,
        module = line.Package,
      }

      if test.module == "command-line-arguments" then
        test.module = nil
      end

      if parent then
        tests[line.Package][parent] = tests[line.Package][parent] or test
        tests[line.Package][parent].tests = tests[line.Package][parent].tests or {}

        test.name = get_subtest_name(line.Test, parent)
        test.real_name = get_subtest_real_name(line.Test, parent)

        tests[line.Package][parent].tests[test.name] = tests[line.Package][parent].tests[test.name] or test
        test = tests[line.Package][parent].tests[test.name]
      else
        tests[line.Package][line.Test] = tests[line.Package][line.Test] or test
        test = tests[line.Package][line.Test]
      end

      test.failed = line.Action == GoTestResultAction.FAIL or nil
      test.skipped = line.Action == GoTestResultAction.SKIP or nil
      test.passed = line.Action == GoTestResultAction.PASS or nil
      test.ignored = not test.failed and not test.skipped and not test.passed

      if line.Output then
        local output = line.Output and vim.fn.trim(line.Output)

        if
          not vim.startswith(output, "=== RUN")
          and not vim.startswith(output, "=== PAUSE")
          and not vim.startswith(output, "=== CONT")
          and not vim.startswith(output, "--- FAIL")
          and not vim.startswith(output, "--- PASS")
          and not vim.startswith(output, "--- SKIP")
        then
          output = vim.fn.trim(line.Output, "\n ", 2)
          test.output = test.output or {}
          test.output = vim.list_extend(test.output, { output })
        end
      end
    end
  end

  self._tests = {}

  for _, parents in pairs(tests) do
    for _, parent in pairs(parents) do
      if parent.module == "command-line-arguments" then
        parent.module = nil
      end

      if parent.failed then
        parent.file, parent.lineno, parent.output = parse_failed_output(parent.output)
      end

      table.insert(self._tests, parent)

      if parent.tests then
        local subtests = {}

        for _, subtest in pairs(parent.tests) do
          if subtest.failed then
            subtest.file, subtest.lineno, subtest.output = parse_failed_output(subtest.output)
          end

          table.insert(subtests, subtest)
        end

        parent.tests = vim.fn.sort(subtests, function(a, b)
          return cmp(a.name, b.name)
        end)
      end
    end
  end

  self._tests = vim.fn.sort(self._tests, function(a, b)
    return cmp((a.module or "") .. "#" .. a.name, (b.module or "") .. "#" .. b.name)
  end)

  return vim.fn.deepcopy(self._tests)
end

return M
