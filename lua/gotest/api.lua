local Cli = require("gotest.new_cli")
local Util = require("gotest.util")
local Notify = require("gotest.notify")
local test_file = require("gotest.test_file")
local Output = require("gotest.view.output")
local Diagnostics = require("gotest.diagnostics")
local parse = require("gotest.gotest_parse")

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
  assert(bufnr and bufnr >= 0, "bufnr must be a valid buffer number")

  if not Util.is_test_file(bufnr) then
    return
  end

  local test_names, subtest_name = test_file.get_current_test(bufnr)
  if not test_names then
    return
  end

  local file_path = Util.get_relative_dir_path(bufnr)
  local cmd = Cli.build_gotest_cmd("./" .. file_path, test_names, subtest_name)

  Notify.info("Tests running...")

  local lines, exit_code = Cli.exec_cmd(cmd)
  local view = Output.new(self.opts.output)
  local output_lines = {
    {
      text = vim.fn.join(cmd, " "),
      highlight = "Comment",
    },
    {},
  }

  local ok, tests = pcall(parse, lines)
  if not ok then
    for i in ipairs(lines) do
      table.insert(output_lines, {
        text = lines[i],
        highlight = "DiagnosticError",
      })
    end

    view:show(output_lines)

    return
  end

  local failed = exit_code ~= 0

  if failed then
    Notify.info("Tests FAILED")
  else
    Notify.info("Tests PASSED")
  end

  for i, test in ipairs(tests) do
    if (failed and test.failed) or not failed or #test.output > 0 then
      local name = test.name
      if test.parent then
        name = " ┗━ " .. string.gsub(name, "^" .. test.parent .. "/", "")
      end

      table.insert(output_lines, {
        text = name,
        highlight = (test.failed and "DiagnosticError") or "DiagnosticHint",
      })

      for _, line in ipairs(test.output) do
        if not test.failed then
          line = "\t" .. line
        end

        table.insert(output_lines, {
          text = line,
        })
      end
    end
  end

  view:show(output_lines)
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
