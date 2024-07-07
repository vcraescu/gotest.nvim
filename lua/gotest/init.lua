local cmds = require("gotest.go.commands")
local ns = vim.api.nvim_create_namespace("gotests")

local M = {
	config = {
		output = {
			focus = {
				fail = true,
				success = false,
			},
		},
		timeout = 30,
		disable_test_cache = false,
		diagnostics = {
			enabled = true,
		},
	},
}

---@param config table
function M.go_test_nearest(config)
	cmds.go_test_nearest(ns, config)
end

---@param opts table
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts)

	vim.api.nvim_create_user_command("GoTestNearest", function()
		return M.go_test_nearest(M.config)
	end, { force = true, desc = "Run the nearest go test" })
end

return M
