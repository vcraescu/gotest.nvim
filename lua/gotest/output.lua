local Notify = require("gotest.notify")
local Util = require("gotest.util")
local Diagnostics = require("gotest.diagnostics")

local M = {}

---@param bufnr integer
---@param cmd string[]
---@param results gotest.GoTestOutputLine[]
---@param opts gotest.Config
local function show_output(bufnr, cmd, results, opts)
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

  Util.open_quickfix(qflist, opts.output.height)
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

    local output = {}

    for _, result in ipairs(results) do
      if result.Action == "output" then
        table.insert(output, result.Output)
      end
    end

    local windId = vim.api.nvim_get_current_win()

    if opts.diagnostics.enabled then
      Diagnostics.clear(bufnr)
      Diagnostics.show(bufnr, results)
    end

    if tests_failed then
      Notify.warn("Tests FAILED")

      if opts.output.show.fail then
        show_output(bufnr, cmd, results, opts)

        if not opts.output.focus.fail then
          vim.api.nvim_set_current_win(windId)
        end
      end

      return
    end

    Notify.info("Tests PASSED")

    if opts.output.show.success then
      show_output(bufnr, cmd, results, opts)

      if not opts.output.focus.success then
        vim.api.nvim_set_current_win(windId)
      end
    end
  end
end

return M
