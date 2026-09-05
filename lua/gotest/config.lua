local M = {}

---@type gotest.Config
local defaults = {
  view = {
    type = "split",
    height = 15,
    float = {
      width = 0.8,
      height = 0.8,
    },
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

---@param opts? gotest.ConfigOpts
---@return gotest.Config
function M.setup(opts)
  return vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
