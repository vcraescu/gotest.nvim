local Api = require("gotest.api")
local Config = require("gotest.config")
local Notify = require("gotest.notify")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("api", function()
  local api

  after_each(function()
    if api then
      local buf = api._view._win._buf
      api:deactivate()
      if buf then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end)

  it("should warn when there is no previous test run", function()
    api = Api.new(Config.setup())
    local warn_spy = spy.on(Notify, "warn")

    api:toggle()

    assert.spy(warn_spy).was_called_with("No previous test run found")
    Notify.warn:revert()
  end)

  it("should open the last test run when it is closed", function()
    api = Api.new(Config.setup({ view = { type = "float", float = { width = 40, height = 10 } } }))
    api._cmd = { "go", "test" }
    api._results = { { Output = "test output", Test = "TestExample", Action = "pass" } }
    api._failed = false

    api:toggle()

    assert.is.truthy(api._view:is_open())
    assert.are.same(api._view._win._win, vim.api.nvim_get_current_win())
    assert.are.same({ "test output" }, vim.api.nvim_buf_get_lines(api._view._win._buf, 0, -1, false))
  end)

  it("should close the last test run when it is open", function()
    api = Api.new(Config.setup())
    api._cmd = { "go", "test" }
    api._results = { { Output = "test output", Test = "TestExample", Action = "pass" } }
    api._failed = false

    api:toggle()
    local win_id = api._view._win._win
    api:toggle()

    assert.is.falsy(api._view:is_open())
    assert.is.falsy(vim.api.nvim_win_is_valid(win_id))
  end)

  it("should reopen the last test run after closing it", function()
    api = Api.new(Config.setup())
    api._cmd = { "go", "test" }
    api._results = { { Output = "test output", Test = "TestExample", Action = "pass" } }
    api._failed = false

    api:toggle()
    local first_win = api._view._win._win
    api:toggle()
    api:toggle()

    assert.is.truthy(api._view:is_open())
    assert.are.same({ "test output" }, vim.api.nvim_buf_get_lines(api._view._win._buf, 0, -1, false))
    assert.is.falsy(vim.api.nvim_win_is_valid(first_win))
  end)

  it("should toggle the view when q is pressed", function()
    api = Api.new(Config.setup({ view = { type = "split", height = 10 } }))
    api._cmd = { "go", "test" }
    api._results = { { Output = "test output", Test = "TestExample", Action = "pass" } }
    api._failed = false

    api:toggle()
    assert.is.truthy(api._view:is_open())

    vim.api.nvim_feedkeys("q", "mx", false)
    vim.wait(100)

    assert.is.falsy(api._view:is_open())
  end)
end)
