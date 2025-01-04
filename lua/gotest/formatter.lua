local M = {}

local FAILED_HIGHLIGHT = "DiagnosticError"
local PASS_HIGHLIGHT = "DiagnosticHint"
local COMMAND_HIGHLIGHT = "Comment"
local SKIP_HIGHLIGHT = "DiagnosticWarn"

---@param test gotest.GoTestNode
---@param prefix? string
---@return gotest.OutputLine
local function format_test_name(test, prefix)
  local out = {
    text = (prefix or "") .. test.name,
    highlight = PASS_HIGHLIGHT,
  }

  if test.skipped then
    out.highlight = SKIP_HIGHLIGHT
  elseif test.failed then
    out.highlight = FAILED_HIGHLIGHT
  end

  return out
end

---@param test gotest.GoTestNode
---@return gotest.OutputLine[]
local function format_test_output(test)
  local lines = {}

  for _, line in ipairs(test.output or {}) do
    if not test.failed then
      line = "\t" .. line
    end

    table.insert(lines, {
      text = line,
    })
  end

  return lines
end

---@param cmd string[]
---@return gotest.OutputLine[]
local function format_cmd(cmd)
  return {
    {
      text = vim.fn.join(cmd, " "),
      highlight = COMMAND_HIGHLIGHT,
    },
    {},
  }
end

---@param cmd string[]
---@param lines string[]
---@return gotest.OutputLine[]
function M.format_error(cmd, lines)
  local out = format_cmd(cmd)

  for i in ipairs(lines) do
    table.insert(out, {
      text = lines[i],
      highlight = FAILED_HIGHLIGHT,
    })
  end

  return out
end

---@class gotest.FormattedLine
---@field text string
---@field highlight string
---
---@param cmd string[]
---@param exit_code integer
---@param tests gotest.GoTestNode[]
---@return gotest.FormattedLine[]
function M.format_tests(cmd, exit_code, tests)
  local failed = exit_code ~= 0
  local out = format_cmd(cmd)

  --- @type fun(test: gotest.GoTestNode): boolean
  local should_display_test = function(test)
    return (failed and test.failed) or not failed or (test.output and #test.output > 0)
  end

  for _, test in ipairs(tests) do
    if should_display_test(test) then
      table.insert(out, format_test_name(test))
      out = vim.list_extend(out, format_test_output(test))

      for _, subtest in pairs(test.tests or {}) do
        if should_display_test(subtest) then
          table.insert(out, format_test_name(subtest, " ┗━ "))
          out = vim.list_extend(out, format_test_output(subtest))
        end
      end

      table.insert(out, { text = "" })
    end
  end

  return out
end

return M
