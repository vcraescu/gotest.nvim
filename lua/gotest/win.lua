--- @class gotest.win.highlight
--- @field higroup string
--- @field start number[]
--- @field finish number[]

--- @class gotest.Win
--- @field opts gotest.win.Config
--- @field _buf number
--- @field _win number
--- @field _ns number
--- @field _title string
--- @field _text string[]
--- @field _highlights gotest.win.highlight[]
local M = {}

--- @class gotest.win.Config
--- @field height? number
--- @field keys? table<string, string>
local defaults = {
  height = 15,
  keys = {
    q = "close",
  },
}

--- @return number
local function create_buf()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "hide"
  vim.api.nvim_set_option_value("buflisted", false, { buf = buf })

  return buf
end

--- @param opts? gotest.win.Config
--- @return gotest.Win
function M.new(opts)
  return setmetatable({
    opts = vim.tbl_extend("force", defaults, opts or {}),
    _buf = create_buf(),
    _win = nil,
    _text = {},
    _highlights = {},
    _ns = vim.api.nvim_create_namespace(""),
  }, { __index = M })
end

--- @param title string|string[]
function M:set_title(title)
  self:_create_win()

  if type(title) == "string" then
    title = { title }
  end

  title = vim.fn.join(title, " ")
  vim.api.nvim_set_option_value("winbar", title, { win = self._win })
end

--- @param text string|string[]
--- @param start_line? number
function M:set_text(text, start_line)
  self:_create_win()

  if type(text) == "string" then
    text = { text }
  end

  if not start_line then
    self:_clear_buf()
  end

  self:_set_buf_lines(text, start_line)
end

--- @param line_no number
--- @param col_no number
function M:set_cursor(line_no, col_no)
  self:_create_win()

  vim.api.nvim_win_set_cursor(self._win, { line_no, col_no })
end

--- @return number
--- @return number
function M:get_cursor()
  self:_create_win()

  local cursor = vim.api.nvim_win_get_cursor(self._win)

  return cursor[1], cursor[2]
end

function M:set_keymap(key, method)
  self:_create_win()

  vim.keymap.set("n", key, function()
    method()
  end, { buffer = self._buf, noremap = true, silent = true })
end

--- @param highlights gotest.win.highlight|gotest.win.highlight[]
function M:set_highlights(highlights)
  self:_create_win()

  if #highlights == 0 then
    highlights = { highlights }
  end

  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_clear_namespace(self._buf, self._ns, hl.start[1], hl.finish[1])
  end

  for _, hl in ipairs(highlights) do
    vim.hl.range(self._buf, self._ns, hl.higroup, hl.start, hl.finish)
  end
end

function M:close()
  self:_close_win()
end

function M:destroy()
  self:close()
  self._buf = nil
  self._win = nil
end

function M:focus()
  self:_create_win()
  vim.api.nvim_set_current_win(self._win)
end

function M:scroll(offset)
  self:_create_win()

  local line_count = vim.api.nvim_buf_line_count(self._buf)
  if offset < 0 then
    offset = line_count
  end

  local cursor = vim.api.nvim_win_get_cursor(self._win)
  local new_cursor = math.min(cursor[1] + offset, line_count)

  if new_cursor < 0 then
    new_cursor = 0
  end

  self:set_cursor(new_cursor, 0)
end

--- @private
function M:_create_win()
  if self:_win_exists() then
    return
  end

  for key, method in pairs(self.opts.keys) do
    vim.keymap.set("n", key, function()
      self[method](self)
    end, { buffer = self._buf, noremap = true })
  end

  self._win = vim.api.nvim_open_win(self._buf, false, {
    split = "below",
    win = vim.api.nvim_get_current_win(),
    height = self.opts.height,
  })
  vim.wo[self._win].winfixheight = true
  vim.api.nvim_win_call(self._win, function()
    vim.cmd.wincmd("J")
  end)
end

--- @private
--- @param lines string[]
--- @param start? number
function M:_set_buf_lines(lines, start)
  if not lines or #lines == 0 then
    return
  end

  start = start or 0

  local buf_lines = {}

  for _, line in ipairs(lines) do
    vim.list_extend(buf_lines, vim.fn.split(line, "\n"))
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = self._buf })
  vim.api.nvim_buf_set_lines(self._buf, start, -1, false, buf_lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self._buf })
end

function M:_clear_buf()
  vim.api.nvim_buf_clear_namespace(self._buf, self._ns, 0, -1)
  vim.api.nvim_set_option_value("modifiable", true, { buf = self._buf })
  vim.api.nvim_buf_set_lines(self._buf, 0, -1, false, {})
  vim.api.nvim_set_option_value("modifiable", false, { buf = self._buf })
end

--- @private
function M:_close_win()
  _ = self:_win_exists() and vim.api.nvim_win_hide(self._win)
end

--- @private
--- @return boolean
function M:_win_exists()
  return self._win and vim.api.nvim_win_is_valid(self._win)
end

return M
