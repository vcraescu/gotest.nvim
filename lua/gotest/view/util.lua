local M = {}

--- @return number
function M.create_buf()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>close<cr>", { noremap = true, silent = true })

  return bufnr
end

---@param bufnr number
---@param height number
---@return number
function M.create_win(bufnr, height)
  local current_win = vim.api.nvim_get_current_win()

  vim.cmd.new()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, height)
  vim.wo.winfixheight = true

  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_win_set_height(0, height)
  vim.api.nvim_set_current_win(current_win)

  return win
end

---@param bufnr number
---@param lines string[]
---@return nil
function M.set_buf_lines(bufnr, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

function M.close_buf(bufnr)
  if bufnr then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

function M.close_win(win)
  if win then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

---@param win number
---@param bufnr number
function M.scroll_to_bottom(win, bufnr)
  local last_line = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(win, { last_line, 0 })
end

---@param bufnr number
---@return boolean
function M.buf_exists(bufnr)
  if not bufnr then
    return false
  end

  return vim.api.nvim_buf_is_valid(bufnr)
end

---@param win number
---@return boolean
function M.win_exists(win)
  if not win then
    return false
  end

  return vim.api.nvim_win_is_valid(win)
end

return M
