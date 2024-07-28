local Notify = require("gotest.notify")
local Util = require("gotest.util")
local Diagnostics = require("gotest.diagnostics")

local M = {}

---@param bufnr integer
---@param lines string[]
local function set_output_highlights(bufnr, lines)
  vim.api.nvim_buf_clear_namespace(bufnr, 0, 0, -1)
  vim.api.nvim_buf_add_highlight(bufnr, 0, "Comment", 0, 0, -1)

  for i, line in ipairs(lines) do
    if string.find(line, "=== CONT") or string.find(line, "=== RUN") or string.find(line, "=== PAUSE") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "Comment", i - 1, 0, -1)
    elseif string.find(line, "--- PASS") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticHint", i - 1, 0, -1)
    elseif string.find(line, "--- FAIL") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticError", i - 1, 0, -1)
    elseif string.find(line, "--- SKIP") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticWarn", i - 1, 0, -1)
    elseif string.match(line, ".*.go:%d+:$") then
      vim.api.nvim_buf_add_highlight(bufnr, 0, "DiagnosticInfo", i - 1, 0, -1)
    end
  end
end

---@param cmd string[]
---@param results gotest.GoTestOutputLine[]
---@param opts gotest.Config
local function show_output(cmd, results, opts)
  local lines = {
    vim.fn.join(cmd, " "),
    "",
  }

  for _, result in ipairs(results) do
    if result.Output then
      local line, _ = string.gsub(result.Output, "%s+$", "")
      table.insert(lines, line)
    end
  end

  local bufnr = Util.open_bottom_buf(lines, opts.output.height)

  set_output_highlights(bufnr, lines)
end

---@param bufnr integer
---@param cmd string[]
---@param opts gotest.Config
---@return fun(lines: gotest.GoTestOutputLine[], exit_code: integer, timeout: integer): nil
function M.new(bufnr, cmd, opts)
  return function(lines, exit_code, timeout)
    if timeout > 0 then
      Notify.warn(string.format("Tests TIMED OUT after %dms", timeout))

      return
    end

    local tests_failed = exit_code ~= 0
    local ok, results = pcall(Util.json_decode_tests, lines)

    if not ok then
      results = vim.tbl_map(function(line)
        return {
          Action = "output",
          Output = line,
        }
      end, lines)
    end

    local windId = vim.api.nvim_get_current_win()

    if opts.diagnostics.enabled then
      Diagnostics.clear(bufnr)
      Diagnostics.show(bufnr, results)
    end

    if tests_failed then
      Notify.error("Tests FAILED")

      if opts.output.show.fail then
        show_output(cmd, results, opts)

        if not opts.output.focus.fail then
          vim.api.nvim_set_current_win(windId)
        end
      end

      return
    end

    Notify.info("Tests PASSED")

    if opts.output.show.success then
      show_output(cmd, results, opts)

      if not opts.output.focus.success then
        vim.api.nvim_set_current_win(windId)
      end
    end
  end
end

return M
