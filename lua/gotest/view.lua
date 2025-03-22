--- @class gotest.View
--- @field opts gotest.Config.view
--- @field _buf number
--- @field _win number
--- @field _ns number
local M = {}

local FAILED_HL = "DiagnosticError"
local PASSED_HL = "DiagnosticHint"
local IGNORED_HL = "Ignore"
local SKIPPED_HL = "DiagnosticWarn"

--- @param opts? gotest.Config.view
function M.new(opts)
  return setmetatable({
    opts = opts or {},
    _ns = vim.api.nvim_create_namespace(""),
  }, { __index = M })
end

--- @param cmd string[]
--- @param tests gotest.GoTestNode[]
--- @param failed boolean
function M:show_tests(cmd, tests, failed)
  local lines = self:_get_tests_output(tests)

  self:_show_win(vim.fn.join(cmd, " "), lines)

  if failed and self:_is_build_failed(tests) then
    vim.hl.range(self._buf, self._ns, FAILED_HL, { 1, 0 }, { #lines, -1 })

    self:_try_focus(failed)

    return
  end

  local nodes = M._to_tree_nodes(tests)
  assert(nodes, "no tests found")

  local tree_view = require("gotest.view.tree.view").new(nodes, self._win, self.opts.tree)

  tree_view:open()
  self:_try_focus(failed)
end

--- @param cmd string[]
--- @param results gotest.GoTestResult[]
--- @param failed boolean
function M:show_results(cmd, results, failed)
  local lines = {}

  for _, result in ipairs(results) do
    table.insert(lines, result.Output)
  end

  self:_show_win(vim.fn.join(cmd, " "), lines)
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
      vim.api.nvim_set_current_win(self._win)

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
      local hl = test.ignored and IGNORED_HL
      hl = (test.failed and FAILED_HL) or hl
      hl = test.skipped and SKIPPED_HL or hl
      hl = test.passed and PASSED_HL or hl

      local node = {
        name = { value = test.name, hl = hl },
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

--- @private
--- @param title string
--- @param lines string[]
function M:_show_win(title, lines)
  if not self:_buf_exists() then
    self:_create_buf()
  end

  if not self:_win_exists() then
    self:_create_win(self.opts.height)
  end

  vim.api.nvim_set_option_value("winbar", title, { win = self._win })
  self:_clear_buf()
  self:_set_buf_lines(lines)
end

function M:hide()
  self:_close_win()
  self:_close_buf()
end

function M:destroy()
  self:hide()
  self._buf = nil
  self._win = nil
end

--- @private
function M:_create_buf()
  self._buf = vim.api.nvim_create_buf(false, true)
  vim.bo[self._buf].buftype = "nofile"
  vim.bo[self._buf].swapfile = false
  vim.bo[self._buf].bufhidden = "wipe"
  vim.api.nvim_set_option_value("buflisted", false, { buf = self._buf }) -- Mark the buffer as unlisted

  vim.keymap.set("n", "q", function()
    self:hide()
  end, { buffer = self._buf, remap = true })
end

--- @private
function M:_close_buf()
  _ = self:_buf_exists() and vim.api.nvim_buf_delete(self._buf, { force = false })
  self._buf = nil
end

--- @private
--- @param height number
function M:_create_win(height)
  local current_win = vim.api.nvim_get_current_win()

  self._win = vim.api.nvim_open_win(self._buf, false, {
    split = "below",
    win = current_win,
    height = height,
  })
  vim.wo[self._win].winfixheight = true
  vim.api.nvim_set_current_win(self._win)
  vim.cmd.wincmd("J")

  vim.schedule(function()
    vim.api.nvim_set_current_win(current_win)
  end)
end

--- @private
--- @param lines string[]
function M:_set_buf_lines(lines)
  if not lines or #lines == 0 then
    return
  end

  local buf_lines = {}

  for _, line in ipairs(lines) do
    vim.list_extend(buf_lines, vim.fn.split(line, "\n"))
  end

  vim.api.nvim_buf_clear_namespace(self._buf, self._ns, 0, -1)
  vim.api.nvim_set_option_value("modifiable", true, { buf = self._buf })
  vim.api.nvim_buf_set_lines(self._buf, 0, -1, false, buf_lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self._buf })
end

function M:_clear_buf()
  vim.api.nvim_set_option_value("modifiable", true, { buf = self._buf })
  vim.api.nvim_buf_set_lines(self._buf, 0, -1, false, {})
  vim.api.nvim_set_option_value("modifiable", false, { buf = self._buf })
end

--- @private
function M:_close_win()
  _ = self:_win_exists() and vim.api.nvim_win_close(self._win, true)
  self._win = nil
end

--- @private
--- @return boolean
function M:_buf_exists()
  return self._buf and vim.api.nvim_buf_is_valid(self._buf)
end

--- @private
--- @return boolean
function M:_win_exists()
  return self._win and vim.api.nvim_win_is_valid(self._win)
end

return M
