package.loaded["lua.gotest.test_output_parse"] = nil

local parse = require("lua.gotest.test_output_parse")

--- @param file_path string
--- @return string[]
--- @return string? error
local function read_file(file_path)
  local file, err = io.open(file_path, "r") -- "r" is for read mode
  if not file then
    return {}, err
  end

  local lines = {}

  for line in file:lines() do
    table.insert(lines, line)
  end

  return lines, nil
end

local lines, err = read_file("output.json")
if err then
  print(err)

  return
end

lines, err = parse(lines)
if err then
  print(err)

  return
end

print(vim.inspect(lines))
