--- @class gotest.View
--- @field opts gotest.Config.view
--- @field _buf number
--- @field _win gotest.Win
--- @field _ns number
local M = {}

local FAILED_HL = "Error"
local PASSED_HL = "DiagnosticHint"
local IGNORED_HL = "Ignore"
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
function M:show_tests(cmd, tests, failed)
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

  local mounted_at = (#lines > 0 and #lines - 1) or 0

  --- @type gotest.tree.View
  local view = require("gotest.view.tree.view").new(mounted_at, nodes, self._win, self.opts.tree)

  view:render()
  self:_try_focus(failed)
end

--- @param cmd string[]
--- @param results gotest.GoTestResult[]
--- @param failed boolean
function M:show_results(cmd, results, failed)
  local lines = {}
  local build_failed = false

  for _, result in ipairs(results) do
    if result.Action == "build-fail" then
      build_failed = true
    end

    table.insert(lines, result.Output)
  end

  self._win:set_title(cmd)
  self._win:set_text(lines)

  if build_failed then
    self._win:set_highlights({ higroup = FAILED_HL, start = { 0, -1 }, finish = { #lines, -1 } })
  end

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
  vim.schedule(function()
    if (failed and self.opts.focus.fail) or (not failed and self.opts.focus.success) then
      self._win:focus()

      return
    end
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
        expanded = (test.failed or (test.output and vim.fn.empty(test.output) == 0)) and true,
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
