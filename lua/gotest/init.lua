local cmds = require("gotest.go.commands")
local ns = vim.api.nvim_create_namespace("gotests")

local M = {}
local default_timeout = 30000

function M.go_test_nearest(opts)
  cmds.go_test_nearest(ns, opts)
end

function M.setup(opts)
  opts = opts or {}

  if not opts.timeout or opts.timeout == 0 then
    opts.timeout = default_timeout
  end

  vim.api.nvim_create_user_command("GoTestNearest", function()
    return M.go_test_nearest(opts)
  end, { force = true, desc = "Run the nearest go test" })
end

return M
