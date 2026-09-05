local Config = require("gotest.config")
local View = require("gotest.view")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("view", function()
  local view

  after_each(function()
    if view then
      local buf = view._win._buf
      view:destroy()
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)

  it("should render results in the configured float", function()
    local opts = Config.setup({ view = { type = "float", float = { width = 40, height = 10 } } })
    view = View.new(opts.view)
    view:render_raw({ "go", "test" }, { { Output = "test output", Test = "TestExample", Action = "pass" } }, false)
    local config = vim.api.nvim_win_get_config(view._win._win)

    assert.are.same("editor", config.relative)
    assert.are.same(40, config.width)
    assert.are.same(10, config.height)
    assert.are.same({ "test output" }, vim.api.nvim_buf_get_lines(view._win._buf, 0, -1, false))
    assert.is.truthy(vim.wo[view._win._win].winbar:find("1/1 passed", 1, true))

    local win_id = view._win._win
    view:hide()
    assert.is.falsy(vim.api.nvim_win_is_valid(win_id))
  end)
end)
