local M = {}

local query_table_test_name = [[ 
    (literal_value (
      literal_element (
        literal_value .(
          keyed_element
            (literal_element (identifier))
            (literal_element ( interpreted_string_literal (interpreted_string_literal_content) @test.name))
         )
       ) @test.block
    ))
  ]]
local query_func_def_line_no = [[
    (
      function_declaration name: (identifier) @func_name
      (#eq? @func_name "%s")
    )
  ]]
local query_sub_test_name = [[ 
    (call_expression
      (selector_expression
        (field_identifier) @method.name)
      (argument_list
        (interpreted_string_literal (interpreted_string_literal_content) @tc.name)
        (func_literal) )
      (#eq? @method.name "Run")
    ) @tc.run 
  ]]

---@param bufnr integer?
---@return TSNode?
local function get_root_node(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "go")
  if not parser then
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  return tree:root()
end

---@param bufnr integer?
---@return string?
function M.get_current_func_name(bufnr)
  assert(bufnr and bufnr > 0, "bufnr must be a valid buffer number")

  local node = vim.treesitter.get_node()
  if not node then
    return
  end

  while node do
    if node:type() == "function_declaration" then
      break
    end

    node = node:parent()
  end

  if not node then
    return
  end

  return vim.treesitter.get_node_text(node:child(1), bufnr)
end

---@param bufnr number?
---@param name string
---@return integer?
function M.get_func_def_line_no(bufnr, name)
  assert(bufnr and bufnr > 0, "bufnr must be a valid buffer number")
  assert(name, "name must be a string")

  local find_func_by_name_query = string.format(query_func_def_line_no, name)
  bufnr = bufnr or 0

  local root = get_root_node(bufnr)
  if not root then
    return
  end

  local query = vim.treesitter.query.parse("go", find_func_by_name_query)

  for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "func_name" then
      local row, _, _ = node:start()

      return row
    end
  end
end

---@param bufnr integer
---@return string?
function M.get_current_table_test_name(bufnr)
  assert(bufnr and bufnr > 0, "bufnr must be a valid buffer number")

  local root = get_root_node(bufnr)
  if not root then
    return
  end

  local query = vim.treesitter.query.parse("go", query_table_test_name)
  local curr_row, _ = unpack(vim.api.nvim_win_get_cursor(0))

  for _, match, _ in query:iter_matches(root, bufnr, 0, -1) do
    local tc_name = nil

    for id, node in pairs(match) do
      local name = query.captures[id]

      if name == "test.name" then
        tc_name = vim.treesitter.get_node_text(node, bufnr)
      end

      if name == "test.block" then
        local start_row, _, end_row, _ = node:range()
        if curr_row >= start_row and curr_row <= end_row then
          return tc_name
        end
      end
    end
  end

  return nil
end

---@param bufnr integer?
---@return string?
function M.get_current_sub_test_name(bufnr)
  assert(bufnr and bufnr > 0, "bufnr must be a valid buffer number")

  local root = get_root_node(bufnr)
  if not root then
    return
  end

  local query = vim.treesitter.query.parse("go", query_sub_test_name)
  local is_inside_test = false
  local curr_row, _ = unpack(vim.api.nvim_win_get_cursor(0))

  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local name = query.captures[id]
    -- tc_run is the first capture of a match, so we can use it to check if we are inside a test
    if name == "tc.run" then
      local start_row, _, end_row, _ = node:range()

      is_inside_test = curr_row >= start_row and curr_row <= end_row
    elseif name == "tc.name" and is_inside_test then
      return vim.treesitter.get_node_text(node, bufnr)
    end
  end

  return nil
end

---@param bufnr integer
---@return string?, string? test name and table test name or sub test name
function M.get_current_test(bufnr)
  assert(bufnr and bufnr > 0, "bufnr must be a valid buffer number")

  local test_name = M.get_current_func_name(bufnr)
  if not test_name then
    return nil
  end

  local table_test_name = M.get_current_table_test_name(bufnr)
  if table_test_name then
    return test_name, table_test_name
  end

  local sub_test_name = M.get_current_sub_test_name(bufnr)

  return test_name, sub_test_name
end

return M
