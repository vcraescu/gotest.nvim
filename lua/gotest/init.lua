local Config = require("gotest.config")
local Api = require("gotest.api")

local M = {}

---@param opts? gotest.Config
function M.setup(opts)
	opts = Config.setup(opts)

	vim.api.nvim_create_user_command("GoTestNearest", function()
		return Api.go_test_nearest(0, opts)
	end, { force = true, desc = "Run the nearest go test" })
end

return setmetatable(M, {
	__index = function(_, key)
		return Api[key]
	end,
})
