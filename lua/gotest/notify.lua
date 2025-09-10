local M = {}

---@param msg string
function M.warn(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg, "DiagnosticWarn" } }, true, {})
  end)
end

---@param msg string
function M.error(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg, "DiagnosticError" } }, true, {})
  end)
end

---@param msg string
function M.success(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg, "DiagnosticHint" } }, true, {})
  end)
end

---@param msg string
function M.info(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg, "DiagnosticInfo" } }, true, {})
  end)
end

return M
