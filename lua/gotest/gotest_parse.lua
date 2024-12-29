--- @class TestJSON
--- @field Action string
--- @field Package string
--- @field Test string
--- @field Output string

--- @param lines string[]
--- @return TestJSON[]
--- @return string? error
local function json_decode_lines(lines)
  --- @type TestJSON[]
  local output = {}

  for i, line in ipairs(lines) do
    local ok, decoded_line = pcall(vim.fn.json_decode, line)
    if not ok then
      return {}, lines[i]
    end

    table.insert(output, decoded_line)
  end

  return output
end

--- @param lines TestJSON[]
--- @return table
--- @return string? error
local function parse(lines)
  local tests = {}
  local err, decoded_lines

  decoded_lines, err = json_decode_lines(lines)
  if err then
    return {}, err
  end

  for _, line in ipairs(decoded_lines) do
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
          table.insert(tests[line.Package][line.Test].output, output)
        end
      end
    end
  end

  return tests, nil
end

--- @param tests table
--- @param module_name string
--- @param test_name string
local function get_test_parent(tests, module_name, test_name)
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
    file = vim.trim(file)
    lineno = tonumber(vim.trim(lineno), 10)
  end

  lines = vim.list_slice(lines, 3, #lines - 1)

  return file, lineno, lines
end

--- @class Test
--- @field module string
--- @field name string
--- @field failed boolean?
--- @field parent string?
--- @field real_name string?
--- @field line string?
--- @field lineno number?
--- @field output string[]

--- @param tests table
--- @param module_name string
--- @param test_name string
--- @param test Test
local function new_test(tests, module_name, test_name, test)
  test = {
    module = module_name,
    name = test_name,
    failed = test.failed or nil,
    parent = get_test_parent(tests, module_name, test_name),
    output = test.output,
  }

  if test.parent then
    test.real_name = get_test_real_name(test.name, test.parent)
  end

  if test.failed and test.output then
    test.line, test.lineno, test.output = parse_failed_output(test.output)
  end

  return test
end

--- @param lines string[]
--- @return Test[]
return function(lines)
  local tests = parse(lines)
  local output = {}

  for module_name, module_tests in pairs(tests) do
    for test_name, test in pairs(module_tests) do
      table.insert(output, new_test(tests, module_name, test_name, test))
    end
  end

  return output
end
