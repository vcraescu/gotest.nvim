local M = {}

---@return boolean
function M.is_test_file()
	return vim.endswith(vim.fn.expand("%"), "_test.go")
end

---@param lines string[]
---@return table[]
function M.json_decode_tests(lines)
	return vim.tbl_map(function(line)
		return vim.fn.json_decode(line)
	end, lines)
end

---@return string
function M.get_current_module_path()
	local path = vim.fn.expand("%:p:h")
	local relative_path = vim.fn.fnamemodify(path, ":.")

	if path == relative_path then
		return "."
	end

	return "./" .. relative_path
end

---@param list table
---@param height number
function M.open_quickfix(list, height)
	vim.fn.setqflist(list, "r")

	vim.cmd.copen()
	vim.cmd.clast()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, height)
	vim.wo.winfixheight = true
end

function M.strip_empty_lines(lines)
	return vim.tbl_filter(function(line)
		return line ~= ""
	end, lines)
end

return M
