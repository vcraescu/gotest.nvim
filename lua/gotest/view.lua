--- @type gotest.View
local M = {
  opts = nil,
  _win = nil,
  _buf = 0,
  _ns = 0,
}

local FAILED_HL = "DiagnosticError"
local PASSED_HL = "DiagnosticOk"
local IGNORED_HL = "DiagnosticUnnecessary"

--- @param opts? gotest.Config.view
--- @return gotest.View
function M.new(opts)
  opts = opts or {}

  return setmetatable({
    opts = opts,
    _win = require("gotest.win").new({ height = opts.height }),
  }, { __index = M })
end

--- @param cmd string[]
--- @param results gotest.GoTestResult[]
--- @param failed boolean
function M:render_raw(cmd, results, failed)
  local lines = {}

  --- @type gotest.win.highlight[]
  local highlights = {}

  for _, result in ipairs(results) do
    local line = result.Output

    if line then
      table.insert(lines, line)

      line = vim.fn.trim(line, " ")

      local higroup

      if vim.startswith(line, "=== PAUSE") or vim.startswith(line, "=== CONT") then
        higroup = IGNORED_HL
      elseif vim.startswith(line, "--- PASS") or vim.startswith(line, "PASS") then
        higroup = PASSED_HL
      elseif vim.startswith(line, "--- FAIL") or vim.startswith(line, "FAIL") then
        higroup = FAILED_HL
      end

      if higroup then
        table.insert(highlights, { higroup = higroup, start = { #lines - 1, 0 }, finish = { #lines - 1, -1 } })
      end
    end
  end

  self._win:set_title(cmd)
  self._win:set_text(lines)
  self._win:set_highlights(highlights)
  self._win:scroll(-1)

  self:_try_focus(failed)
end

function M:_try_focus(failed)
  if (failed and not self.opts.focus_on_fail) or (not failed and not self.opts.focus_on_success) then
    return
  end

  vim.schedule(function()
    self._win:focus()
  end)
end

function M:hide()
  self._win:close()
end

function M:destroy()
  self._win:destroy()
end

return M
