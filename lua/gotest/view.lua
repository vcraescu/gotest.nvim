--- @class gotest.View
--- @field opts gotest.Config.view
--- @field _buf number
--- @field _win gotest.Win
--- @field _ns number
local M = {}

local FAILED_HL = "DiagnosticError"
local PASSED_HL = "DiagnosticHint"
local IGNORED_HL = "DiagnosticUnnecessary"
local SKIPPED_HL = "DiagnosticWarn"

--- @param opts? gotest.Config.view
--- @return gotest.View
function M.new(opts)
  opts = opts or {}

  return setmetatable({
    opts = opts,
    _ns = vim.api.nvim_create_namespace(""),
    _win = require("gotest.win").new({ height = opts.height }),
  }, { __index = M })
end

--- @param cmd string[]
--- @param tests gotest.GoTestNode[]
--- @param failed boolean
function M:render_tree(cmd, tests, failed)
  local lines = self:_get_tests_output(tests)

  self._win:set_title(cmd)
  self._win:set_text(lines)

  if failed and self:_is_build_failed(tests) then
    self._win:set_highlights({ higroup = FAILED_HL, start = { 1, -1 }, finish = { #lines, -1 } })

    self:_try_focus(failed)

    return
  end

  local nodes = M._to_tree_nodes(tests)
  assert(nodes, "no tests found")

  --- @type gotest.tree.View
  local view = require("gotest.view.tree.view").new(#lines, nodes, self._win, self.opts.tree)

  view:render()
  self:_try_focus(failed)
end

--- @param cmd string[]
--- @param results gotest.GoTestResult[]
--- @param failed boolean
function M:render_raw(cmd, results, failed)
  local lines = {}

  --- @type gotest.win.highlight[]
  local highlights = {}

  for _, result in ipairs(results) do
    local line = result.Output

    if line then
      table.insert(lines, line)

      line = vim.fn.trim(line, " ")

      local higroup

      if vim.startswith(line, "=== PAUSE") or vim.startswith(line, "=== CONT") then
        higroup = IGNORED_HL
      elseif vim.startswith(line, "--- PASS") or vim.startswith(line, "PASS") then
        higroup = PASSED_HL
      elseif vim.startswith(line, "--- FAIL") or vim.startswith(line, "FAIL") then
        higroup = FAILED_HL
      end

      if higroup then
        table.insert(highlights, { higroup = higroup, start = { #lines - 1, 0 }, finish = { #lines - 1, -1 } })
      end
    end
  end

  self._win:set_title(cmd)
  self._win:set_text(lines)
  self._win:set_highlights(highlights)
  self._win:scroll(-1)

  self:_try_focus(failed)
end

function M:_get_tests_output(tests)
  local lines = {}

  for _, test in ipairs(tests) do
    if (test.passed or test.tests or not test.name) and test.output then
      vim.list_extend(lines, test.output)
    end

    for _, subtest in ipairs(test.tests or {}) do
      if subtest.passed and subtest.output then
        vim.list_extend(lines, subtest.output)
      end
    end
  end

  if #lines > 0 then
    table.insert(lines, #lines + 1, "")
  end

  return lines
end

function M:_try_focus(failed)
  if (failed and not self.opts.focus_on_fail) or (not failed and not self.opts.focus_on_success) then
    return
  end

  vim.schedule(function()
    self._win:focus()
  end)
end

--- @param tests gotest.GoTestNode[]
--- @return boolean
function M:_is_build_failed(tests)
  for _, test in ipairs(tests) do
    if not test.name then
      return true
    end
  end

  return false
end

--- @private
--- @param tests gotest.GoTestNode[]
--- @return gotest.tree.Node[]?
function M._to_tree_nodes(tests)
  if not tests or #tests == 0 then
    return nil
  end

  local tree = {}

  tests = M.sort_failed_tests_first(tests)

  for _, test in ipairs(tests) do
    if test.name then
      local higroup = test.ignored and IGNORED_HL
      higroup = (test.failed and FAILED_HL) or higroup
      higroup = test.skipped and SKIPPED_HL or higroup
      higroup = test.passed and PASSED_HL or higroup

      --- @type gotest.tree.Node
      local node = {
        name = { value = test.name, higroup = higroup },
        expanded = true,
        text = test.output,
      }

      if test.passed then
        node.text = nil
      end

      if test.tests and #test.tests > 0 then
        node.children = M._to_tree_nodes(test.tests)

        for _, child in ipairs(node.children) do
          if child.expanded then
            node.expanded = true

            break
          end
        end
      end

      table.insert(tree, node)
    end
  end

  return #tree > 0 and tree or nil
end

function M.sort_failed_tests_first(tests)
  return vim.fn.sort(tests, function(a, b)
    if a.failed then
      return -1
    end

    if b.failed then
      return 1
    end

    return 0
  end)
end

function M:hide()
  self._win:close()
end

function M:destroy()
  self._win:destroy()
end

return M
