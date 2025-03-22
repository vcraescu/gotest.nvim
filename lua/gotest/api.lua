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
    local results = parser:parse_results()

    -- return self._view:show_results(cmd, results, failed)
    local tests = parser:parse()
    if tests then
      return self._view:show_tests(cmd, tests, failed)
    end
  end)

  -- for _, test in ipairs(tests) do
  --   if test.failed and test.file then
  --     table.insert(qf_items, {
  --       filename = test.file,
  --       lnum = test.lineno,
  --       col = 0,
  --       text = test.name,
  --     })
  --     table.insert(qf_items, {
  --       filename = test.file,
  --       lnum = test.lineno,
  --       col = 0,
  --       text = vim.fn.join(test.output, "\n"),
  --     })
  --   end
  -- end
  --
  -- vim.fn.setqflist(qf_items, "r")
  -- vim.cmd("copen")

  -- local func_names = Ts.get_nearest_func_names(bufnr)
  -- if not func_names or #func_names == 0 then
  --   return Notify.warn("No tests to run")
  -- end
  --
  -- local subtest_name = nil
  --
  -- if #func_names == 1 then
  --   subtest_name = Ts.get_tbl_testcase_name(bufnr)
  --
  --   if not subtest_name then
  --     subtest_name = Ts.get_sub_testcase_name(bufnr)
  --   end
  -- end
  --
  -- local cli = Cli.new({
  --   module = Util.get_current_module_path(),
  --   func_names = func_names,
  --   subtest_name = subtest_name,
  -- }, self.opts)
  --
  -- Notify.info("Tests running...")
  --
  -- Diagnostics.clear(bufnr)
  --
  -- cli:exec(function(results, exit_code)
  --   local failed = exit_code ~= 0
  --
  --   if self.opts.diagnostics.enabled then
  --     Diagnostics.show(bufnr, results)
  --   end
  --
  --   if failed then
  --     Notify.error("Tests FAILED")
  --   else
  --     Notify.info("Tests PASSED")
  --   end
  --
  --   self.output:open(cli.cmd, results, failed)
  -- end)
end

return M
