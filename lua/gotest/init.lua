local Config = require("gotest.config")
local Api = require("gotest.api")
local M = {}

--- @param opts? gotest.Config
function M.setup(opts)
  opts = Config.setup(opts)
  local api = Api.new(opts)

  vim.api.nvim_create_user_command("GoTestNearest", function()
    vim.schedule(function()
      api:test_nearest(0)
    end)
  end, { force = true, desc = "Run the nearest go test", nargs = "*" })

  vim.api.nvim_create_user_command("GoTestRetry", function()
    vim.schedule(function()
      api:test_retry()
    end)
  end, { force = true, desc = "Retry previous go tests", nargs = "*" })
end

return M
