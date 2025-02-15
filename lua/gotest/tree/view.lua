--- @class gotest.tree.View
--- @field opts gotest.Config.view.tree
--- @field _nodes gotest.tree.Node[]
--- @field _nodes_list table<number, gotest.tree.Node>
--- @field _ns number
--- @field _buf number
--- @field _win number
--- @field _renderer gotest.tree.Renderer
--- @field _output gotest.tree.Renderer.row[]

--- @class gotest.tree.Node
--- @field name string|gotest.tree.Label
--- @field children? gotest.tree.Node[]
--- @field expanded? boolean
--- @field level number
--- @field text string[]|gotest.tree.Label[]
--- @field id number

--- @class gotest.tree.Label
--- @field value string
--- @field hl? string

local M = {}

math.randomseed(os.time())

local function generate_id()
  ---@diagnostic disable-next-line: undefined-field
  return tostring(vim.loop.hrtime()) .. tostring(math.random(100000, 999999999))
end

--- @param nodes gotest.tree.Node[]
--- @param win number
--- @param opts? gotest.Config.view.tree
function M.new(nodes, win, opts)
  opts = opts or {}
  local _nodes = M._init_nodes(nodes, 1)

  return setmetatable({
    opts = opts,
    _nodes = _nodes,
    _nodes_list = M._init_nodes_list(_nodes),
    _ns = vim.api.nvim_create_namespace(""),
    _buf = vim.api.nvim_win_get_buf(win),
    _win = win,
    _output = {},
    _renderer = require("gotest.tree.renderer").new(opts.renderer),
    _mounted_at = 0,
  }, { __index = M })
end

function M:open()
  self._mounted_at = vim.api.nvim_buf_line_count(self._buf)

  self:_setup_keymaps()
  self:_render()
end

function M:toggle_current_node()
  local cursor = vim.api.nvim_win_get_cursor(self._win)
  local line = self._output[cursor[1] - self._mounted_at]
  if not line or not line.node_id then
    return nil
  end

  return self:toggle_node(self._nodes_list[line.node_id])
end

function M:toggle_node(node)
  if not node then
    return
  end

  node.expanded = not node.expanded

  self:_render()
end

--- @private
function M:_render()
  self._output = self._renderer:render(self._nodes)

  vim.api.nvim_buf_clear_namespace(self._buf, self._ns, 0, -1)

  local lines, highlights = {}, {}

  for i, line in ipairs(self._output) do
    table.insert(lines, line.text)

    if line.highlight then
      table.insert(highlights, {
        group = line.highlight.group,
        line = self._mounted_at + i - 1,
        col_start = line.highlight.col_start or 0,
        col_end = line.highlight.col_end or -1,
      })
    end
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = self._buf })
  vim.api.nvim_buf_set_lines(self._buf, self._mounted_at, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self._buf })

  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(self._buf, self._ns, hl.group, hl.line, hl.col_start or 0, hl.col_end or -1)
  end
end

--- @private
function M:_setup_keymaps()
  local opts = { noremap = true, silent = true, buffer = self._buf }

  vim.keymap.set("n", "<CR>", function()
    self:toggle_current_node()
  end, opts)
  vim.keymap.set("n", "o", function()
    self:toggle_current_node()
  end, opts)
end

--- @private
--- @param nodes gotest.tree.Node[]?
--- @return table<string, gotest.tree.Node>
function M._init_nodes_list(nodes)
  local out = {}
  if not nodes then
    return out
  end

  for _, node in ipairs(nodes) do
    out[node.id] = node

    if node.children and #node.children > 0 then
      out = vim.tbl_extend("force", out, M._init_nodes_list(node.children))
    end
  end

  return out
end

--- @private
--- @param nodes gotest.tree.Node[]
--- @param level number
--- @return gotest.tree.Node[]?
function M._init_nodes(nodes, level)
  local out = {}

  if not nodes then
    return nil
  end

  for _, node in ipairs(nodes) do
    table.insert(
      out,
      vim.tbl_deep_extend("force", node, {
        id = "id-" .. generate_id(),
        children = M._init_nodes(node.children, level + 1),
        level = level,
      })
    )
  end

  return out
end

return M
