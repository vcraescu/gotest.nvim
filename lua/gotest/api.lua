local Cli = require("gotest.cli")
local Notify = require("gotest.notify")
local TestFile = require("gotest.test_file")
local View = require("gotest.view")
local Diagnostics = require("gotest.diagnostics")
local Parser = require("gotest.parser")

---@class gotest.Api
---@field opts gotest.Config
---@field _view gotest.View
local M = {}

---@param opts gotest.Config
function M.new(opts)
  local self = setmetatable({}, { __index = M })

  self.opts = opts or {}
  self._view = View.new(self.opts.view)

  return self
end

---@param bufnr integer
function M:test_nearest(bufnr)
  local file = TestFile.new(bufnr)

  if not file:is_test() then
    Notify.warn("Not a Go test file")

    return
  end

  local test_names, subtest_name = file:get_current_test()
  if not test_names then
    Notify.warn("No tests found")

    return
  end

  local file_path = file:get_dir()
  local cmd = Cli.build_gotest_cmd("./" .. file_path, test_names, subtest_name)

  Notify.info("Tests running...")

  Cli.exec_cmd({ cmd = cmd }, function(lines, exit_code)
    local failed = exit_code ~= 0

    if failed then
      Notify.error("Tests FAILED")
    else
      Notify.success("Tests PASSED")
    end

    local parser = Parser.new(lines)
    -- local results = parser:parse_results()

    -- return self._view:show_results(cmd, results, failed)
    local tests = parser:parse()
    if tests then
      return self._view:show_tests(cmd, tests, failed)
    end
  end)
end

return M
