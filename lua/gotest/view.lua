local Highlights = require("gotest.highlights")

--- @class gotest.View
local M = {}

--- @param opts? gotest.Config.view
--- @return gotest.View
function M.new(opts)
  opts = opts or {}

  return setmetatable({
    opts = opts,
    _win = require("gotest.win").new({ height = opts.height }),
  }, { __index = M })
end

--- @param results gotest.GoTestResult[]
--- @return table<string, boolean>
local function find_parent_tests(results)
  local parents = {}

  for _, result in ipairs(results) do
    if result.Test then
      local parent = result.Test:match("^(.+)/[^/]+$")
      if parent then
        parents[parent] = true
      end
    end
  end

  return parents
end

--- @param results gotest.GoTestResult[]
--- @return gotest.GoTestStats
local function compute_stats(results)
  local stats = { total = 0, passed = 0, failed = 0, skipped = 0 }
  local parents = find_parent_tests(results)

  for _, result in ipairs(results) do
    if result.Test and not parents[result.Test] then
      if result.Action == "pass" then
        stats.total = stats.total + 1
        stats.passed = stats.passed + 1
      elseif result.Action == "fail" then
        stats.total = stats.total + 1
        stats.failed = stats.failed + 1
      elseif result.Action == "skip" then
        stats.total = stats.total + 1
        stats.skipped = stats.skipped + 1
      end
    end
  end

  return stats
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
        higroup = Highlights.IGNORED
      elseif vim.startswith(line, "--- PASS") or vim.startswith(line, "PASS") then
        higroup = Highlights.PASSED
      elseif vim.startswith(line, "--- FAIL") or vim.startswith(line, "FAIL") then
        higroup = Highlights.FAILED
      end

      if higroup then
        table.insert(highlights, { higroup = higroup, start = { #lines - 1, 0 }, finish = { #lines - 1, -1 } })
      end
    end
  end

  local stats = compute_stats(results)
  self._win:set_title(cmd, stats)
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
