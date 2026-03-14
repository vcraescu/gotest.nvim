local Ts = require("gotest.ts")

local M = {}

local ns = vim.api.nvim_create_namespace("gotest")

---@param bufnr integer
---@param results gotest.GoTestResult[]
function M.show(bufnr, results)
  bufnr = bufnr or 0
  results = results or {}
  local diagnostics = {}

  for _, result in ipairs(results) do
    if result.Test and result.Action == "fail" then
      local line_no = Ts.get_func_def_line_no(bufnr, result.Test)

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

---@param bufnr integer
function M.clear(bufnr)
  bufnr = bufnr or 0

  vim.diagnostic.set(ns, bufnr, {}, {})
end

return M
