local Config = require("gotest.config")
local Ts = require("gotest.ts")

local M = {}

---@param bufnr integer
---@param results gotest.GoTestOutputLine[]
function M.show(bufnr, results)
  local diagnostics = {}

  for _, result in ipairs(results) do
    if result.Action == "fail" then
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

  vim.diagnostic.set(Config._ns, bufnr, diagnostics, {})
end

---@param bufnr integer
function M.clear(bufnr)
  vim.diagnostic.set(Config._ns, bufnr, {}, {})
end

return M
