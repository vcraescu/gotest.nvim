local M = {}

---@class gotest.Config.view.tree.icons
---@field closed string
---@field opened string

---@class gotest.Config.view.tree
---@field indent string
---@field icons gotest.Config.view.tree.icons

---@class gotest.Config.view
---@field focus_on_fail boolean
---@field focus_on_success boolean
---@field show_on_fail boolean
---@field show_on_success boolean
---@field height number
---@field tree gotest.Config.view.tree
---@field type '"tree"' | '"raw"'

---@class gotest.Config.diagnostics
---@field enabled boolean

---@class gotest.Config
---@field view gotest.Config.view
---@field timeout number
---@field disable_test_cache boolean
---@field diagnostics gotest.Config.diagnostics
local defaults = {
  view = {
    type = "tree",
    height = 15,
    focus_on_fail = true,
    focus_on_success = false,
    show_on_fail = true,
    show_on_success = true,
    tree = {
      indent = "  ",
      icons = {
        closed = " ",
        opened = " ",
      },
    },
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

  options["_ns"] = vim.api.nvim_create_namespace("gotest")

  return options
end

return setmetatable(M, {
  __index = function(_, key)
    options = options or M.setup()
    assert(options, "should be setup")

    return options[key]
  end,
})
