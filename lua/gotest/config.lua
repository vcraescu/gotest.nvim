local M = {}

---@class gotest.Config.view.focus
---@field fail boolean
---@field success boolean

---@class gotest.Config.view.show
---@field fail boolean
---@field success boolean

---@class gotest.Config.view.tree.renderer.icons
---@field closed string
---@field opened string

---@class gotest.Config.view.tree.renderer
---@field indent string
---@field icons gotest.Config.view.tree.renderer.icons

---@class gotest.Config.view.tree
---@field renderer gotest.Config.view.tree.renderer

---@class gotest.Config.view
---@field focus gotest.Config.view.focus
---@field height number
---@field show gotest.Config.view.show
---@field tree gotest.Config.view.tree

---@class gotest.Config.diagnostics
---@field enabled boolean

---@class gotest.Config
---@field view gotest.Config.view
---@field timeout number
---@field disable_test_cache boolean
---@field diagnostics gotest.Config.diagnostics
local defaults = {
  view = {
    focus = {
      fail = true,
      success = false,
    },
    height = 15,
    show = {
      fail = true,
      success = true,
    },
    tree = {
      renderer = {
        indent = "  ",
        icons = {
          closed = " ",
          opened = " ",
          passed = "󰸞 ",
        },
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
