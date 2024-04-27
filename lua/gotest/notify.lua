local M = {}

local function notify(msg, level)
  vim.schedule(function()
    vim.api.nvim_notify(msg, level, {})
  end)
end

function M.warn(msg)
  notify(msg, vim.log.levels.WARN)
end

function M.info(msg)
  notify(msg, vim.log.levels.INFO)
end

return M
