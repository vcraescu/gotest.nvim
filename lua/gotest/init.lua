local Config = require("gotest.config")
local Api = require("gotest.api")
local M = {}

---@param opts? gotest.Config
function M.setup(opts)
  opts = Config.setup(opts)
  local api = Api.new(opts)

  vim.api.nvim_create_user_command("GoTestNearest", function()
    M._run_user_command(function()
      api:test_nearest(0)
    end)
  end, { force = true, desc = "Run the nearest go test", nargs = "*" })

  vim.api.nvim_create_user_command("GoTestRetry", function()
    M._run_user_command(function()
      api:test_retry()
    end)
  end, { force = true, desc = "Retry previous go tests", nargs = "*" })
end

---@param fn fun()
function M._run_user_command(fn)
  local timer = vim.uv.new_timer()
  assert(timer, "Failed to create uv timer")

  return timer:start(0, 0, function()
    vim.schedule(function()
      local co = coroutine.create(function()
        fn()
        timer:close()
      end)

      coroutine.resume(co)
    end)
  end)
end

return M
