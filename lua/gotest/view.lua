---@class gotest.View
---@field _opts gotest.Config.view
---@field _buf number
---@field _win number
local M = {}

--- @return number
local function create_buf()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>close<cr>", { noremap = true, silent = true })

  return bufnr
end

---@param bufnr number
---@param height number
---@return number
local function create_win(bufnr, height)
  local current_win = vim.api.nvim_get_current_win()

  vim.cmd.new()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, height)
  vim.wo.winfixheight = true

  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_win_set_height(0, height)

  -- we need to schedule this operation otherwise it will fail because of BufEnter autocmd from nvim-lint
  vim.schedule(function()
    vim.api.nvim_set_current_win(current_win)
  end)

  return win
end

---@param bufnr number
---@param lines string[]
---@return nil
local function set_buf_lines(bufnr, lines)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

local function close_buf(bufnr)
  if bufnr then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

local function close_win(win)
  if win then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

---@param bufnr number
---@return boolean
local function buf_exists(bufnr)
  if not bufnr then
    return false
  end

  return vim.api.nvim_buf_is_valid(bufnr)
end

---@param win number
---@return boolean
local function win_exists(win)
  if not win then
    return false
  end

  return vim.api.nvim_win_is_valid(win)
end

---@param opts? gotest.Config.view
function M.new(opts)
  return setmetatable({ _opts = opts or {} }, { __index = M })
end

---@param lines gotest.FormattedLine[]
function M:show(lines)
  if not buf_exists(self._buf) then
    close_buf(self._buf)
    self._buf = create_buf()
  end

  if not win_exists(self._win) then
    close_win(self._win)
    self._win = create_win(self._buf, self._opts.height)
  end

  local buf_lines = {}

  for _, line in ipairs(lines) do
    if not line.text then
      line.text = ""
    end

    table.insert(buf_lines, vim.fn.trim(line.text, "\n"))
  end

  vim.api.nvim_buf_clear_namespace(self._buf, 0, 0, -1)
  set_buf_lines(self._buf, buf_lines)

  for index, line in ipairs(lines) do
    if line.highlight then
      vim.api.nvim_buf_add_highlight(self._buf, 0, line.highlight, index - 1, 0, -1)
    end
  end

  vim.api.nvim_set_current_win(self._win)
end

function M:hide()
  close_buf(self._buf)
  close_win(self._win)
end

function M:destroy()
  self:hide()
  self._buf = nil
  self._win = nil
end

return M
