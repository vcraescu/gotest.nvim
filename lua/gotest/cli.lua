local M = {}

---@class gotest.Cli.opts
---@field cached? boolean
---@field timeout? number

---@param path string?
---@param test_names string[]?
---@param subtest_name string?
---@param opts? gotest.Cli.opts
---@return string[]
function M.build_gotest_cmd(path, test_names, subtest_name, opts)
  opts = opts or {}

  path = path and vim.fn.trim(path)
  subtest_name = subtest_name and vim.fn.trim(subtest_name)

  if path == "" then
    path = nil
  end

  if subtest_name == "" then
    subtest_name = nil
  end

  if subtest_name then
    assert(test_names and #test_names == 1, "Expected non-nil test_names")
  end

  assert(path or test_names and #test_names == 1, "Expected non-nil path or test_names")

  local output = {
    "go",
    "test",
    "-v",
    "-json",
  }

  if not opts.cached then
    table.insert(output, "-count=1")
  end

  if opts.timeout and opts.timeout > 0 then
    table.insert(output, string.format("-timeout=%ds", opts.timeout))
  end

  if path then
    table.insert(output, path)
  end

  if test_names and #test_names >= 1 then
    local run_arg = {}

    test_names = vim.tbl_map(function(test_name)
      return string.format([[^\Q%s\E$]], test_name)
    end, test_names)

    table.insert(run_arg, vim.fn.join(test_names, "|"))

    if subtest_name then
      table.insert(run_arg, string.format([[^\Q%s\E$]], subtest_name))
    end

    table.insert(output, string.format("-run=%s", vim.fn.join(run_arg, "/")))
  end

  return output
end

---@class gotest.Cli.command
---@field cmd string[]
---@field cwd? string

---@param cmd gotest.Cli.command
---@param callback fun(output: string[], exit_code: integer)
---@return integer job_id
function M.exec_cmd(cmd, callback)
  assert(cmd.cmd, "Expected non-nil cmd")

  local std_output, err_output = {}, {}

  local capture_output = function(dst)
    return function(_, lines)
      lines = vim.tbl_filter(function(line)
        return line ~= ""
      end, lines)

      vim.list_extend(dst, lines)
    end
  end

  local job_id = vim.fn.jobstart(cmd.cmd, {
    cwd = cmd.cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = capture_output(std_output),
    on_stderr = capture_output(err_output),
    on_exit = function(_, exit_code)
      vim.schedule(function()
        local output = std_output

        if #err_output > 0 then
          output = err_output
        end

        callback(output, exit_code)
      end)
    end,
  })

  assert(job_id, "Expected non-nil job_id")

  return job_id
end

return M
