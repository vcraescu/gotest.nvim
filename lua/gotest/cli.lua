local Util = require("gotest.util")

---@class gotest.Cli
---@field opts gotest.Config
---@field cmd string[]
local M = {}
M.__index = M

---@param context gotest.CliContext
---@param opts gotest.Config
---@return string[]
local function build_cmd(context, opts)
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

  if context.module and context.module ~= "." then
    table.insert(cmd, context.module)
  end

  local run_arg = nil

  if #context.func_names > 0 then
    local func_names = vim.tbl_map(function(v)
      return string.format([[^\Q%s\E$]], v)
    end, context.func_names)

    run_arg = string.format([[%s]], vim.fn.join(func_names, "|"))
  end

  if #context.func_names == 1 and context.subtest_name then
    local subtest_name = string.match(context.subtest_name, [["(.+)"]])

    if subtest_name then
      run_arg = vim.fn.join({ run_arg, string.format([[^\Q%s\E$]], subtest_name) }, "/")
    end
  end

  if run_arg then
    table.insert(cmd, string.format("-run=%s", run_arg))
  end

  return cmd
end

---@class gotest.CliContext
---@field module string
---@field func_names? string[]
---@field subtest_name? string

---@class gotest.CliOutputLine
---@field Time string
---@field Action string
---@field Package string
---@field Test string
---@field Output string

---@param context gotest.CliContext
---@param opts? gotest.Config
---@return gotest.Cli
function M.new(context, opts)
  local self = setmetatable({}, M)
  self.opts = opts or {}
  self.cmd = build_cmd(context, self.opts)

  return self
end

---@param cb fun(output: gotest.CliOutputLine[], exit_code: integer)
---@return integer
function M:exec(cb)
  local std_output, err_output = {}, {}

  return vim.fn.jobstart(self.cmd, {
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

        local ok, results = pcall(Util.json_decode_tests, output)
        if not ok then
          results = vim.tbl_map(function(line)
            return {
              Action = "output",
              Output = line,
            }
          end, output)
        end

        cb(results, exit_code)
      end)
    end,
  })
end

return M
