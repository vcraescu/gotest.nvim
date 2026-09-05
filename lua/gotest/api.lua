local Cli = require("gotest.cli")
local Notify = require("gotest.notify")
local TestFile = require("gotest.test_file")
local View = require("gotest.view")
local Diagnostics = require("gotest.diagnostics")
local Parser = require("gotest.parser")

---@class gotest.Api
local M = {}

---@param opts gotest.Config
function M.new(opts)
  local self = setmetatable({}, { __index = M })

  self.opts = opts or {}
  self._view = View.new(self.opts.view, function()
    self:toggle()
  end)

  return self
end

---@param bufnr integer
function M:test_nearest(bufnr)
  local file = TestFile.new(bufnr)

  if not file:is_test() then
    Notify.warn("Not a Go test file")

    return
  end

  if not file:has_tests() then
    Notify.warn("No tests found")

    return
  end

  local test_names, subtest_name = file:get_current_test()
  local file_path = file:get_dir()
  self._cmd = Cli.build_gotest_cmd("./" .. file_path, test_names, subtest_name)
  self._bufnr = bufnr

  self:_run_tests(bufnr, self._cmd)
end

function M:test_retry()
  if not self._cmd or not self._bufnr then
    Notify.warn("No previous test run found")

    return
  end

  self:_run_tests(self._bufnr, self._cmd)
end

function M:toggle()
  if self._view:is_open() then
    self._view:hide()

    return
  end

  if not self._results then
    Notify.warn("No previous test run found")

    return
  end

  self._view:render_raw(self._cmd, self._results, self._failed)
  self._view:focus()
end

function M:deactivate()
  self._view:destroy()
end

---@param bufnr integer
---@param cmd string[]
function M:_run_tests(bufnr, cmd)
  Notify.info("Tests running...")
  Diagnostics.clear(bufnr)

  Cli.exec_cmd({ cmd = cmd }, function(lines, exit_code)
    local failed = exit_code ~= 0

    if failed then
      Notify.error("Tests FAILED")
    else
      Notify.success("Tests PASSED")
    end

    local results = Parser.parse_results(lines)
    assert(results, "Failed to parse results")
    self._results = results
    self._failed = failed

    if self.opts.diagnostics and self.opts.diagnostics.enabled then
      Diagnostics.show(bufnr, results)
    end

    if (failed and not self.opts.view.show_on_fail) or (not failed and not self.opts.view.show_on_success) then
      return
    end

    return self._view:render_raw(self._cmd, results, failed)
  end)
end

return M
