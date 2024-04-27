local M = {}

---@param cmd string|object
---@param cb fun(output: object, exit_code: integer, timeout: integer)
---@param config object
function M.exec_cmd(cmd, cb, config)
	config = config or {}

	local timed_out = 0
	local std_output = {}
	local err_output = {}
	local strip_empty_lines = function(lines)
		return vim.tbl_filter(function(line)
			return line ~= ""
		end, lines)
	end

	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, lines)
			std_output = strip_empty_lines(lines)
		end,
		on_stderr = function(_, lines)
			err_output = strip_empty_lines(lines)
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				local output = std_output

				if #err_output > 0 then
					output = err_output
				end

				cb(output, exit_code, timed_out)
			end)
		end,
	})

	if job_id <= 0 then
		return
	end

	local timer = vim.loop.new_timer()
	local timeout = config.timeout * 1000

	timer:start(timeout, 0, function()
		vim.schedule(function()
			vim.fn.jobstop(job_id)
			timed_out = timeout
		end)
	end)
end

---@param module string
---@param func_names string[]
---@param subtest_name string?
---@return string[]
function M.build_go_test_cmd(module, func_names, subtest_name)
	local cmd = {
		"go",
		"test",
		"-v",
		"-json",
	}

	if module and module ~= "." then
		table.insert(cmd, module)
	end

	local run_arg = nil

	if #func_names > 0 then
		func_names = vim.tbl_map(function(v)
			return string.format([[^\Q%s\E$]], v)
		end, func_names)

		run_arg = string.format([[%s]], vim.fn.join(func_names, "|"))
	end

	if #func_names == 1 and subtest_name then
		subtest_name = string.match(subtest_name, [["(.+)"]])

		if subtest_name then
			run_arg = vim.fn.join({ run_arg, string.format([[^\Q%s\E$]], subtest_name) }, "/")
		end
	end

	if run_arg then
		table.insert(cmd, string.format("-run=%s", run_arg))
	end

	return cmd
end

return M
