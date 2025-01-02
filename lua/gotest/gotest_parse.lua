--- @class gotest.TestJSON
--- @field Action string
--- @field Package string
--- @field Test string
--- @field Output string

--- @param lines string[]
--- @return gotest.TestJSON[]
local function json_decode_lines(lines)
  assert(lines, "Expected non-nil lines")

  --- @type gotest.TestJSON[]
  local output = {}

  for _, line in ipairs(lines) do
    table.insert(output, vim.fn.json_decode(line))
  end

  return output
end

--- @param lines gotest.TestJSON[]
--- @return table
local function parse(lines)
  assert(lines, "Expected non-nil lines")

  local tests = {}

  for _, line in ipairs(json_decode_lines(lines)) do
    if line.Test then
      tests[line.Package] = tests[line.Package] or {}
      tests[line.Package][line.Test] = tests[line.Package][line.Test] or { output = {} }
      tests[line.Package][line.Test].failed = line.Action == "fail"

      if line.Output then
        local output = vim.fn.trim(line.Output)

        if
          not vim.startswith(output, "=== RUN")
          and not vim.startswith(output, "=== PAUSE")
          and not vim.startswith(output, "=== CONT")
          and not vim.startswith(output, "--- FAIL")
          and not vim.startswith(output, "--- PASS")
        then
          table.insert(tests[line.Package][line.Test].output, vim.fn.trim(line.Output, "\n ", 2))
        end
      end
    end
  end

  return tests
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
local function get_test_real_name(test_name, parent)
  assert(test_name, "Expected non-nil test_name")
  assert(parent, "Expected non-nil parent")

  test_name = string.gsub(test_name, parent .. "/", "")
  test_name = string.gsub(test_name, "_", " ")

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

    file = vim.trim(file)
    lineno = tonumber(vim.trim(lineno), 10)
  end

  lines = vim.list_slice(lines, 2, #lines - 1)

  return file, lineno, lines
end

--- @class gotest.Test
--- @field module string?
--- @field name string
--- @field failed boolean?
--- @field parent string?
--- @field real_name string?
--- @field file string?
--- @field lineno number?
--- @field output string[]

--- @param tests table
--- @param module_name string
--- @param test_name string
--- @param test gotest.Test
local function new_test(tests, module_name, test_name, test)
  test = {
    name = test_name,
    failed = test.failed or nil,
    parent = get_test_parent(tests, module_name, test_name),
    output = test.output,
  }

  if module_name ~= "command-line-arguments" then
    test.module = module_name
  end

  if test.parent then
    test.real_name = get_test_real_name(test.name, test.parent)
  end

  if test.failed and test.output then
    test.file, test.lineno, test.output = parse_failed_output(test.output)
  end

  return test
end

--- @param lines string[]
--- @return gotest.Test[]
return function(lines)
  local tests = parse(lines)
  local output = {}

  for module_name, module_tests in pairs(tests) do
    for test_name, test in pairs(module_tests) do
      table.insert(output, new_test(tests, module_name, test_name, test))
    end
  end

  output = vim.fn.sort(output, function(a, b)
    local a_sort = vim.fn.join({ (a.module or ""), (a.parent or ""), a.name }, "#")
    local b_sort = vim.fn.join({ (b.module or ""), (b.parent or ""), b.name }, "#")

    if a_sort < b_sort then
      return -1
    elseif a_sort > b_sort then
      return 1
    end

    return 0
  end)

  return output
end
