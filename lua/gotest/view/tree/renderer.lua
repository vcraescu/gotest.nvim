--- @class gotest.tree.Renderer
--- @field opts gotest.Config.view.tree.renderer
local M = {}

--- @class gotest.tree.Renderer.row
--- @field node_id? string
--- @field text string
--- @field highlight gotest.win.highlight

--- @param opts? gotest.Config.view.tree.renderer
function M.new(opts)
  return setmetatable({ opts = opts }, { __index = M })
end

--- @param nodes gotest.tree.Node[]
--- @return gotest.tree.Renderer.row[]
function M:render(nodes)
  if not nodes then
    return {}
  end

  local out = {}

  for _, node in ipairs(nodes) do
    vim.list_extend(out, self:_render_node(node))
  end

  return out
end

--- @private
--- @param node gotest.tree.Node
--- @return gotest.tree.Renderer.row
function M:_render_node(node)
  local out = {
    self:_render_node_name(node),
  }

  if not self:_is_expanded(node) then
    return out
  end

  if node.text and (not node.children or #node.children == 0) then
    vim.list_extend(out, self:_render_node_text(node))
  end

  vim.list_extend(out, self:render(node.children))

  return out
end

--- @private
--- @param s string|gotest.tree.Label|string[]|gotest.tree.Label[]
--- @return string|string[]
function M:_get_text(s)
  if type(s) == "string" then
    return s
  end

  if s.value then
    return s.value
  end

  local out = {}

  for _, v in ipairs(s) do
    if v.value then
      table.insert(out, v.value)
    elseif type(v) == "string" then
      table.insert(out, v)
    end
  end

  return vim.fn.join(out, " ")
end

--- @private
--- @param node gotest.tree.Node
--- @return string
function M:_get_node_prefix(node)
  return string.rep(self.opts.indent, node.level - 1)
end

--- @private
--- @param node gotest.tree.Node
--- @return gotest.tree.Renderer.row[]
function M:_render_node_text(node)
  if not node.text then
    return {}
  end

  local prefix = self:_get_node_prefix(node)
  prefix = prefix .. prefix

  --- @type gotest.tree.Renderer.row[]
  local rows = {}

  for _, line in ipairs(node.text) do
    local text = self:_get_text(line)

    --- @type gotest.tree.Renderer.row
    local row = {
      -- node_id = node.id,
      text = prefix .. text,
      highlight = {
        higroup = line.higroup,
        start = { 0, #prefix },
        finish = { 0, -1 },
      },
    }

    table.insert(rows, row)
  end

  return rows
end

--- @private
--- @param node gotest.tree.Node
--- @return gotest.tree.Renderer.row
function M:_render_node_name(node)
  local prefix = self:_get_node_prefix(node) .. self:_get_node_icon(node)
  local text = self:_get_text(node.name)

  --- @type gotest.tree.Renderer.row
  local row = {
    node_id = node.id,
    text = prefix .. text,
    highlight = {
      higroup = node.name.higroup,
      start = { 0, #prefix },
      finish = { 0, -1 },
    },
  }

  return row
end

--- @private
--- @param node gotest.tree.Node
--- @return string
function M:_get_node_icon(node)
  if (node.children and #node.children > 0) or (node.text and #node.text > 0) then
    return self:_is_expanded(node) and self.opts.icons.opened or self.opts.icons.closed
  end

  return self.opts.indent
end

--- @private
--- @param node gotest.tree.Node
--- @return boolean
function M:_is_expanded(node)
  return node.expanded or false
end

return M
