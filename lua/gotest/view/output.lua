local Util = require("gotest.view.util")

---@class gotest.Output
---@field opts gotest.Config.output
---@field buf number
---@field win number
---@field current_win number
local M = {}
M.__index = M

---@param opts? gotest.Config.output
function M.new(opts)
  local self = setmetatable({}, M)

  opts = opts or {}
  self.opts = opts

  return self
end

---@param cmd string[]
---@param results gotest.CliOutputLine[]
---@return string[]
local function resultsToLines(cmd, results)
  local lines = {
    vim.fn.join(cmd, " "),
    "",
  }

  for _, result in ipairs(results) do
    if result.Output then
      local line, _ = string.gsub(result.Output, "%s+$", "")
      table.insert(lines, line)
    end
  end

  return lines
end

---@param bufnr integer
---@param lines string[]
local function set_highlights(bufnr, lines)
  vim.api.nvim_buf_clear_namespace(bufnr, 0, 0, -1)
  vim.api.nvim_buf_add_highlight(bufnr, 0, "Comment", 0, 0, -1)

  for i, line in ipairs(lines) do
    if string.find(line, "=== CONT") or string.find(line, "=== RUN") or string.find(line, "=== PAUSE") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "Comment", i - 1, 0, -1)
    elseif string.find(line, "--- PASS") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticHint", i - 1, 0, -1)
    elseif string.find(line, "--- FAIL") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticError", i - 1, 0, -1)
    elseif string.find(line, "--- SKIP") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticWarn", i - 1, 0, -1)
    elseif string.match(line, ".*.go:%d+:$") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticInfo", i - 1, 0, -1)
    end
  end
end

---@param cmd string[]
---@param results gotest.CliOutputLine[]
---@param failed boolean
function M:open(cmd, results, failed)
  if (failed and not self.opts.show.fail) or (not failed and not self.opts.show.success) then
    self:close()

    return
  end

  if not Util.buf_exists(self.buf) then
    Util.close_buf(self.buf)
    self.buf = Util.create_buf()
  end

  if not Util.win_exists(self.win) then
    Util.close_win(self.win)
    self.win = Util.create_win(self.buf, self.opts.height)
  end

  local lines = resultsToLines(cmd, results)

  Util.set_buf_lines(self.buf, lines)
  Util.scroll_to_bottom(self.win, self.buf)

  if (failed and self.opts.focus.fail) or (not failed and self.opts.focus.success) then
    vim.api.nvim_set_current_win(self.win)
  end

  set_highlights(self.buf, lines)
end

function M:close()
  Util.close_buf(self.buf)
  Util.close_win(self.win)
  self.buf = nil
  self.win = nil
end

return M
