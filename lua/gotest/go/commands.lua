local cli = require("gotest.go.cli")
local output = require("gotest.go.output")
local util = require("gotest.go.util")
local notify = require("gotest.notify")
local ts = require("gotest.go.ts")

local M = {}

---@param ns integer
---@param config table
function M.go_test_nearest(ns, config)
	vim.diagnostic.set(ns, 0, {}, {})

	if not util.is_test_file() then
		return
	end

	local func_names = ts.get_nearest_func_names()
	if not func_names or #func_names == 0 then
		return notify.warn("No tests to run")
	end

	local sub_testcase_name = nil

	if #func_names == 1 then
		sub_testcase_name = ts.get_tbl_testcase_name()

		if not sub_testcase_name then
			sub_testcase_name = ts.get_sub_testcase_name()
		end
	end

	local cmd = cli.build_go_test_cmd(util.get_current_module_path(), func_names, sub_testcase_name, config) or ""

	notify.info("Tests running...")

	cli.exec_cmd(cmd, output.new(0, ns, cmd, config), config)
end

return M
