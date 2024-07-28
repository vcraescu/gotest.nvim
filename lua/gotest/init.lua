local Config = require("gotest.config")
local Api = require("gotest.api")
local M = {}

---@param opts? gotest.Config
function M.setup(opts)
  opts = Config.setup(opts)
  local api = Api.new(opts)

  vim.api.nvim_create_user_command("GoTestNearest", function()
    return api:test_nearest(0)
  end, { force = true, desc = "Run the nearest go test" })
end

return M
