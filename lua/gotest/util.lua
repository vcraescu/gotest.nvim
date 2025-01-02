local M = {}

---@return boolean
function M.is_test_file(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)

  return vim.endswith(name, "_test.go")
end

---@param lines string[]
---@return table[]
function M.json_decode_tests(lines)
  return vim.tbl_map(function(line)
    return vim.fn.json_decode(line)
  end, lines)
end

---@return string?
function M.get_relative_dir_path(bufnr)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.:h")
end

function M.strip_empty_lines(lines)
  return vim.tbl_filter(function(line)
    return line ~= ""
  end, lines)
end

return M
