local M = {}

local defaults = {
  view = {
    height = 15,
    focus_on_fail = true,
    focus_on_success = false,
    show_on_fail = true,
    show_on_success = true,
  },
  timeout = 30,
  disable_test_cache = false,
  diagnostics = {
    enabled = true,
  },
}

---@param opts? gotest.Config
---@return gotest.Config
function M.setup(opts)
  return vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
