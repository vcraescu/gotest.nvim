--- @class gotest.tree.View
--- @field opts gotest.Config.view.tree
--- @field _nodes gotest.tree.Node[]
--- @field _nodes_list table<number, gotest.tree.Node>
--- @field _win gotest.Win
--- @field _renderer gotest.tree.Renderer
--- @field _output gotest.tree.Renderer.row[]
--- @field _mounted_at integer

--- @class gotest.tree.Node
--- @field name gotest.tree.Label
--- @field children? gotest.tree.Node[]
--- @field expanded? boolean
--- @field level? number
--- @field text string[]|gotest.tree.Label[]
--- @field id? string

--- @class gotest.tree.Label
--- @field value string
--- @field higroup? string

local M = {}

--- @param mounted_at integer
--- @param nodes gotest.tree.Node[]
--- @param win gotest.Win
--- @param opts? gotest.Config.view.tree
--- @return gotest.tree.View
function M.new(mounted_at, nodes, win, opts)
  opts = opts or {}
  local _nodes = M._init_nodes(nodes, 1)

  return setmetatable({
    opts = opts,
    _nodes = _nodes,
    _nodes_list = M._init_nodes_list(_nodes),
    _win = win,
    _output = {},
    _mounted_at = mounted_at,
    _renderer = require("gotest.view.tree.renderer").new(opts.renderer),
  }, { __index = M })
end

function M:render()
  self:_setup_keymaps()
  self:_render()
end

function M:toggle_current_node()
  local line_no, col_no = self._win:get_cursor()
  local line = self._output[line_no - self._mounted_at]
  if not line or not line.node_id then
    return nil
  end

  self:toggle_node(self._nodes_list[line.node_id])

  self._win:set_cursor(line_no, col_no)
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

  --- @type string[]
  local lines = {}

  --- @type gotest.win.highlight[]
  local highlights = {}

  for i, row in ipairs(self._output) do
    table.insert(lines, row.text)

    if row.highlight then
      row.highlight.start[1] = i - 1 + self._mounted_at
      row.highlight.finish[1] = i - 1 + self._mounted_at

      table.insert(highlights, row.highlight)
    end
  end

  self._win:set_text(lines, self._mounted_at)
  self._win:set_highlights(highlights)
end

--- @private
function M:_setup_keymaps()
  self._win:set_keymap("<CR>", function()
    self:toggle_current_node()
  end)

  self._win:set_keymap("o", function()
    self:toggle_current_node()
  end)
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
        id = "id-" .. require("gotest.unique_id")(),
        children = M._init_nodes(node.children, level + 1),
        level = level,
      })
    )
  end

  return out
end

return M
