local Config = require("gotest.config")
local Api = require("gotest.api")
local M = {
  _api = nil,
}

--- @param opts? gotest.ConfigOpts
function M.setup(opts)
  local config = Config.setup(opts)
  M._api = Api.new(config)

  vim.api.nvim_create_user_command("GoTestNearest", function()
    vim.schedule(function()
      M._api:test_nearest(0)
    end)
  end, { force = true, desc = "Run the nearest go test", nargs = "*" })

  vim.api.nvim_create_user_command("GoTestRetry", function()
    vim.schedule(function()
      M._api:test_retry()
    end)
  end, { force = true, desc = "Retry previous go tests", nargs = "*" })

  vim.api.nvim_create_user_command("GoTestToggle", function()
    vim.schedule(function()
      M._api:toggle()
    end)
  end, { force = true, desc = "Toggle the last test run window", nargs = "*" })
end

function M.deactivate()
  M._api:deactivate()
end

return M
