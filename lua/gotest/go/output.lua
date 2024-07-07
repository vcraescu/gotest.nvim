local notify = require("gotest.notify")
local util = require("gotest.go.util")
local ts = require("gotest.go.ts")

local M = {}

---@param bufnr integer
---@param ns integer
---@param results table
local function show_diagnostics(bufnr, ns, results)
	local diagnostics = {}

	for _, result in ipairs(results) do
		if result.Action == "fail" then
			local line_no = ts.get_func_def_line_no(bufnr, result.Test)

			if line_no then
				table.insert(diagnostics, {
					lnum = line_no,
					col = 0,
					severity = vim.diagnostic.severity.WARN,
					message = "FAILED",
					source = "Test",
					user_data = "test",
				})
			end
		end
	end

	vim.diagnostic.set(ns, bufnr, diagnostics, {})
end

---@param bufnr integer
---@param cmd string[]
---@param results {Action: string, Output: string}[]
---@param config table
local function show_output(bufnr, cmd, results, config)
	bufnr = bufnr or 0

	results = vim.tbl_filter(function(result)
		return result.Action == "output"
	end, results)

	results = vim.tbl_map(function(result)
		return {
			bufnr = bufnr,
			text = result.Output,
		}
	end, results)

	local qflist = { {
		bufnr = bufnr,
		text = vim.fn.join(cmd, " "),
	}, { bufnr = bufnr } }

	for _, value in ipairs(results) do
		table.insert(qflist, value)
	end

	util.open_quickfix(qflist, config.output.height)
end

---@param bufnr integer
---@param ns integer
---@param cmd string[]
---@param config table
---@return fun(lines: string[], exit_code: integer, timeout: integer): nil
function M.new(bufnr, ns, cmd, config)
	return function(lines, exit_code, timeout)
		if timeout > 0 then
			notify.warn(string.format("Tests TIMED OUT after %dms", timeout))

			return
		end

		local tests_failed = exit_code ~= 0
		local ok, results = pcall(util.json_decode_tests, lines)

		if not ok then
			results = vim.tbl_map(function(line)
				return {
					Action = "output",
					Output = line,
				}
			end, lines)
		end

		local output = {}

		for _, result in ipairs(results) do
			if result.Action == "output" then
				table.insert(output, result.Output)
			end
		end

		local windId = vim.api.nvim_get_current_win()

		if config.diagnostics.enabled then
			show_diagnostics(bufnr, ns, results)
		end

		show_output(bufnr, cmd, results, config)

		if tests_failed then
			notify.warn("Tests FAILED")

			if not config.output.focus.fail then
				vim.api.nvim_set_current_win(windId)
			end

			return
		end

		notify.info("Tests PASSED")

		if not config.output.focus.success then
			vim.api.nvim_set_current_win(windId)
		end
	end
end

return M
