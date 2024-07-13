local Cli = require("gotest.cli")
local Output = require("gotest.output")
local Util = require("gotest.util")
local Notify = require("gotest.notify")
local Ts = require("gotest.ts")

local M = {}

---@param opts gotest.Config
function M.go_test_nearest(bufnr, opts)
	if not Util.is_test_file() then
		return
	end

	local func_names = Ts.get_nearest_func_names(bufnr)
	if not func_names or #func_names == 0 then
		return Notify.warn("No tests to run")
	end

	local sub_testcase_name = nil

	if #func_names == 1 then
		sub_testcase_name = Ts.get_tbl_testcase_name(bufnr)

		if not sub_testcase_name then
			sub_testcase_name = Ts.get_sub_testcase_name(bufnr)
		end
	end

	local cmd = Cli.build_go_test_cmd(Util.get_current_module_path(), func_names, sub_testcase_name, opts)

	Notify.info("Tests running...")

	Cli.exec_cmd(cmd, Output.new(0, cmd, opts), opts)
end

return M
