local Util = require("gotest.util")

local M = {}

---@param cmd string|string[]
---@param cb fun(output: gotest.GoTestOutputLine[], exit_code: integer, timeout: integer)
---@param _ gotest.Config
---@return integer
function M.exec_cmd(cmd, cb, _)
  local timed_out = 0
  local std_output, err_output = {}, {}

  return vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, lines)
      std_output = Util.strip_empty_lines(lines)
    end,
    on_stderr = function(_, lines)
      err_output = Util.strip_empty_lines(lines)
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        local output = std_output

        if #err_output > 0 then
          output = err_output
        end

        cb(output, exit_code, timed_out)
      end)
    end,
  })
end

---@param module string
---@param func_names string[]
---@param subtest_name string?
---@param opts gotest.Config
---@return string[]
function M.build_go_test_cmd(module, func_names, subtest_name, opts)
  opts = opts or {}

  local cmd = {
    "go",
    "test",
    "-v",
    "-json",
  }

  if opts.disable_test_cache then
    table.insert(cmd, "-count=1")
  end

  if opts.timeout > 0 then
    table.insert(cmd, string.format("-timeout=%ds", opts.timeout))
  end

  if module and module ~= "." then
    table.insert(cmd, module)
  end

  local run_arg = nil

  if #func_names > 0 then
    func_names = vim.tbl_map(function(v)
      return string.format([[^\Q%s\E$]], v)
    end, func_names)

    run_arg = string.format([[%s]], vim.fn.join(func_names, "|"))
  end

  if #func_names == 1 and subtest_name then
    subtest_name = string.match(subtest_name, [["(.+)"]])

    if subtest_name then
      run_arg = vim.fn.join({ run_arg, string.format([[^\Q%s\E$]], subtest_name) }, "/")
    end
  end

  if run_arg then
    table.insert(cmd, string.format("-run=%s", run_arg))
  end

  return cmd
end

return M
