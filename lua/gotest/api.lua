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
  Diagnostics.clear(bufnr)

  Cli.exec_cmd({ cmd = cmd }, function(lines, exit_code)
    local failed = exit_code ~= 0

    if failed then
      Notify.error("Tests FAILED")

      if not self.opts.view.show_on_fail then
        return
      end
    else
      Notify.success("Tests PASSED")

      if not self.opts.view.show_on_success then
        return
      end
    end

    local parser = Parser.new(lines)
    local results = parser:parse_results()
    assert(results, "Failed to parse results")

    if self.opts.diagnostics and self.opts.diagnostics.enabled then
      Diagnostics.show(bufnr, results)
    end

    if self.opts.view.type == "tree" then
      local tests = parser:parse()
      assert(tests, "Failed to parse tests")

      return self._view:render_tree(cmd, tests, failed)
    end

    return self._view:render_raw(cmd, results, failed)
  end)
end

return M
