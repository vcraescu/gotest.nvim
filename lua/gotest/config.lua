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

---@type gotest.Config
local options

---@param opts? gotest.Config
function M.setup(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend("force", defaults, opts)

  return options
end

return setmetatable(M, {
  __index = function(_, key)
    options = options or M.setup()
    assert(options, "should be setup")

    return options[key]
  end,
})
