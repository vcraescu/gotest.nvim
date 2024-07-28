local Cli = require("gotest.cli")
local Util = require("gotest.util")
local Notify = require("gotest.notify")
local Ts = require("gotest.ts")
local Output = require("gotest.view.output")
local Diagnostics = require("gotest.diagnostics")

---@class gotest.Api
---@field opts gotest.Config
---@field output gotest.Output
local M = {}
M.__index = M

---@param opts gotest.Config
function M.new(opts)
  local self = setmetatable({}, M)

  self.opts = opts or {}
  self.output = Output.new(self.opts.output)

  return self
end

---@param bufnr integer
function M:test_nearest(bufnr)
  if not Util.is_test_file() then
    return
  end

  local func_names = Ts.get_nearest_func_names(bufnr)
  if not func_names or #func_names == 0 then
    return Notify.warn("No tests to run")
  end

  local subtest_name = nil

  if #func_names == 1 then
    subtest_name = Ts.get_tbl_testcase_name(bufnr)

    if not subtest_name then
      subtest_name = Ts.get_sub_testcase_name(bufnr)
    end
  end

  local cli = Cli.new({
    module = Util.get_current_module_path(),
    func_names = func_names,
    subtest_name = subtest_name,
  }, self.opts)

  Notify.info("Tests running...")

  Diagnostics.clear(bufnr)

  cli:exec(function(results, exit_code)
    local failed = exit_code ~= 0

    if self.opts.diagnostics.enabled then
      Diagnostics.show(bufnr, results)
    end

    if failed then
      Notify.error("Tests FAILED")
    else
      Notify.info("Tests PASSED")
    end

    self.output:open(cli.cmd, results, failed)
  end)
end

return M
