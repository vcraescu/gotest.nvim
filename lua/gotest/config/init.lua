local M = {}

---@class gotest.Config
local defaults = {
	output = {
		focus = {
			fail = true,
			success = false,
		},
		height = 15,
		show = {
			fail = true,
			success = true,
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
