local M = {}

local PREFIX = "[gotest] "

---@param msg string
---@param hl string
local function echo(msg, hl)
  vim.schedule(function()
    vim.api.nvim_echo({ { PREFIX .. msg, hl } }, true, {})
  end)
end

---@param msg string
function M.warn(msg)
  echo(msg, "DiagnosticWarn")
end

---@param msg string
function M.error(msg)
  echo(msg, "DiagnosticError")
end

---@param msg string
function M.success(msg)
  echo(msg, "DiagnosticOk")
end

---@param msg string
function M.info(msg)
  echo(msg, "DiagnosticInfo")
end

return M
