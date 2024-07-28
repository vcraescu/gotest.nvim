local M = {}

---@return boolean
function M.is_test_file()
  return vim.endswith(vim.fn.expand("%"), "_test.go")
end

---@param lines string[]
---@return table[]
function M.json_decode_tests(lines)
  return vim.tbl_map(function(line)
    return vim.fn.json_decode(line)
  end, lines)
end

---@return string
function M.get_current_module_path()
  local path = vim.fn.expand("%:p:h")
  local relative_path = vim.fn.fnamemodify(path, ":.")

  if path == relative_path then
    return "."
  end

  return "./" .. relative_path
end

function M.strip_empty_lines(lines)
  return vim.tbl_filter(function(line)
    return line ~= ""
  end, lines)
end

return M
