---@class Opts
---@field cached? boolean
---@field timeout? number

local M = {}

---@param path string?
---@param test_name string?
---@param subtest_name string?
---@param opts? Opts
---@return string[]
function M.build_gotest_cmd(path, test_name, subtest_name, opts)
  opts = opts or {}

  path = path and vim.fn.trim(path)
  test_name = test_name and vim.fn.trim(test_name)
  subtest_name = subtest_name and vim.fn.trim(subtest_name)

  if path == "" then
    path = nil
  end

  if test_name == "" then
    test_name = nil
  end

  if subtest_name == "" then
    subtest_name = nil
  end

  if subtest_name then
    assert(test_name, "Expected non-nil test_name")
  end

  assert(path or test_name, "Expected non-nil path or test_name")

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

  if test_name then
    local run_arg = {}

    table.insert(run_arg, string.format([[^\Q%s\E$]], test_name))

    if subtest_name then
      table.insert(run_arg, string.format([[^\Q%s\E$]], subtest_name))
    end

    table.insert(output, string.format("-run=%s", vim.fn.join(run_arg, "/")))
  end

  return output
end

---@param cmd string[]
---@param cwd? string
---@return string[]
---@return integer exit_code
function M.exec_cmd(cmd, cwd)
  local std_output, err_output = {}, {}
  local exit_code

  local capture_output = function(dst)
    return function(_, lines)
      lines = vim.tbl_filter(function(line)
        return line ~= ""
      end, lines)

      vim.list_extend(dst, lines)
    end
  end

  local job_id = vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = capture_output(std_output),
    on_stderr = capture_output(err_output),
    on_exit = function(_, code)
      exit_code = code
    end,
  })

  assert(job_id, "Expected non-nil job_id")
  _ = vim.fn.jobwait({ job_id })

  local output = std_output

  if #err_output > 0 then
    output = err_output
  end

  return output, exit_code
end

return M
