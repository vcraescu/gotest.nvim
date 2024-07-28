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

--- @param name string
--- @param height number
--- @return number, number Buffer number and window number
local function create_bottom_buf(name, height)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>close<cr>", { noremap = true, silent = true })

  vim.api.nvim_command("botright split")

  local new_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(new_win, bufnr)
  vim.api.nvim_win_set_height(new_win, height)

  return bufnr, new_win
end

---@param bufnr number
---@param lines string[]
---@return nil
local function set_buf_lines(bufnr, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

---@param lines string[]
---@param height number
function M.open_bottom_buf(lines, height)
  local buf_name = "gotest_output"
  local bufnr = vim.fn.bufnr(buf_name)
  local wins = vim.fn.win_findbuf(bufnr)
  local is_buf_visible = #wins > 0
  local new_win

  if #wins > 0 then
    new_win = wins[1]
  end

  if not is_buf_visible and bufnr ~= -1 then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    bufnr = -1
  end

  if bufnr == -1 then
    bufnr, new_win = create_bottom_buf(buf_name, height)
  end

  set_buf_lines(bufnr, lines)

  -- Scroll to the bottom of the buffer
  vim.api.nvim_win_set_cursor(new_win, { #lines, 0 })

  return bufnr
end

function M.strip_empty_lines(lines)
  return vim.tbl_filter(function(line)
    return line ~= ""
  end, lines)
end

return M
