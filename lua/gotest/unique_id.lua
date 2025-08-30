math.randomseed(os.time())

return function()
  ---@diagnostic disable-next-line: undefined-field
  return tostring(vim.loop.hrtime()) .. tostring(math.random(100000, 999999999))
end
