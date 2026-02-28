local M = {}

local msg_prefix = "[gotest] "

---@param msg string
function M.warn(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg_prefix .. msg, "DiagnosticWarn" } }, true, {})
  end)
end

---@param msg string
function M.error(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg_prefix .. msg, "DiagnosticError" } }, true, {})
  end)
end

---@param msg string
function M.success(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg_prefix .. msg, "DiagnosticOk" } }, true, {})
  end)
end

---@param msg string
function M.info(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg_prefix .. msg, "DiagnosticInfo" } }, true, {})
  end)
end

return M
