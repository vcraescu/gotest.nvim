--- @class gotest.View
--- @field opts gotest.Config.view
--- @field _buf number
--- @field _win number
--- @field _ns number
local M = {}

local FAILED_HL = "DiagnosticError"
local PASSED_HL = "DiagnosticHint"
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
function M:show(cmd, tests)
  if not self:_buf_exists() then
    self:_create_buf()
  end

  if not self:_win_exists() then
    self:_create_win(self.opts.height)
  end

  vim.api.nvim_buf_clear_namespace(self._buf, self._ns, 0, -1)

  local lines = {
    vim.fn.join(cmd, " "),
    "",
  }

  for _, test in ipairs(tests) do
    if (test.passed or test.tests) and test.output then
      vim.list_extend(lines, test.output)
    end

    for _, subtest in ipairs(test.tests or {}) do
      if subtest.passed and subtest.output then
        vim.list_extend(lines, subtest.output)
      end
    end
  end

  if #lines > 0 then
    table.insert(lines, "")
  end

  self:_set_buf_lines(lines)

  vim.api.nvim_buf_add_highlight(self._buf, self._ns, "Comment", 0, 0, -1)

  local nodes = M._to_tree_nodes(tests)
  if not nodes then
    return
  end

  local tree_view = require("gotest.tree.view").new(nodes, self._win)

  tree_view:open()
end

--- @param cmd string[]
--- @param lines string[]
function M:show_raw(cmd, lines)
  if not self:_buf_exists() then
    self:_create_buf()
  end

  if not self:_win_exists() then
    self:_create_win(self.opts.height)
  end

  vim.api.nvim_buf_clear_namespace(self._buf, self._ns, 0, -1)

  self:_set_buf_lines({
    vim.fn.join(cmd, " "),
    "",
    unpack(lines),
  })

  vim.api.nvim_buf_add_highlight(self._buf, self._ns, "Comment", 0, 0, -1)
end

--- @param tests gotest.GoTestNode[]
--- @return gotest.tree.Node[]?
function M._to_tree_nodes(tests)
  if not tests then
    return nil
  end

  local tree = {}

  tests = M.sort_failed_tests_first(tests)

  for _, test in ipairs(tests) do
    local hl = test.failed and FAILED_HL
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

    if node.text then
      node.text = vim.tbl_map(function(line)
        return line:gsub("^ *", ""):gsub("^\t", "")
      end, node.text or {})
    end

    if test.tests then
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

  return tree
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
  vim.api.nvim_set_option_value("modifiable", true, { buf = self._buf })
  vim.api.nvim_buf_set_lines(self._buf, 0, -1, false, lines)
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
