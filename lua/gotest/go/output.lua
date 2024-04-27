local notify = require("gotest.notify")
local util = require("gotest.go.util")
local ts = require("gotest.go.ts")

local M = {}

local function show_diagnostics(bufnr, ns, results)
  local diagnostics = {}

  for _, result in ipairs(results) do
    if result.Action == "fail" then
      local line_no = ts.get_func_def_line_no(bufnr, result.Test)

      if line_no then
        table.insert(diagnostics, {
          lnum = line_no,
          col = 0,
          severity = vim.diagnostic.severity.WARN,
          message = "FAILED",
          source = "Test",
          user_data = "test",
        })
      end
    end
  end

  vim.diagnostic.set(ns, bufnr, diagnostics, {})
end

local function show_output(bufnr, cmd, results)
  bufnr = bufnr or 0

  results = vim.tbl_filter(function(result)
    return result.Action == "output"
  end, results)

  results = vim.tbl_map(function(result)
    return {
      bufnr = bufnr,
      text = result.Output,
    }
  end, results)

  local qflist = { {
    bufnr = bufnr,
    text = vim.fn.join(cmd, " "),
  }, { bufnr = bufnr } }

  for _, value in ipairs(results) do
    table.insert(qflist, value)
  end

  vim.fn.setqflist(qflist, "r")
  vim.cmd(string.format("copen | cnext %d", #qflist))
end

function M.new(bufnr, ns, cmd)
  return function(lines, exit_code, timeout)
    if timeout > 0 then
      notify.warn(string.format("Tests TIMED OUT after %dms", timeout))

      return
    end

    if exit_code == 0 then
      notify.info("Tests PASSED")
    else
      notify.warn("Tests FAILED")
    end

    local ok, results = pcall(util.json_decode_tests, lines)

    if not ok then
      results = vim.tbl_map(function(line)
        return {
          Action = "output",
          Output = line,
        }
      end, lines)
    end

    local output = {}

    for _, result in ipairs(results) do
      if result.Action == "output" then
        table.insert(output, result.Output)
      end
    end

    show_diagnostics(bufnr, ns, results)
    show_output(bufnr, cmd, results)
  end
end

return M
