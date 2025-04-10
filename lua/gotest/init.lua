local Config = require("gotest.config")
local Api = require("gotest.api")
local M = {}

---@param opts? gotest.Config
function M.setup(opts)
  opts = Config.setup(opts)
  local api = Api.new(opts)

  vim.api.nvim_create_user_command("GoTestNearest", function(args)
    local timer = vim.uv.new_timer()
    assert(timer, "Failed to create uv timer")

    timer:start(0, 0, function()
      vim.schedule(function()
        local co = coroutine.create(function()
          api:test_nearest(0)
          timer:close()
        end)

        coroutine.resume(co)
      end)
    end)
  end, { force = true, desc = "Run the nearest go test", nargs = "*" })
end

return M
