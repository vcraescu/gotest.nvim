local M = {}

function M.is_test_file()
  return vim.endswith(vim.fn.expand("%"), "_test.go")
end

function M.json_decode_tests(lines)
  return vim.tbl_map(function(line)
    return vim.fn.json_decode(line)
  end, lines)
end

function M.get_current_module_path()
  local path = vim.fn.expand("%:p:h")
  local relative_path = vim.fn.fnamemodify(path, ":.")

  if path == relative_path then
    return "."
  end

  return "./" .. relative_path
end

return M
