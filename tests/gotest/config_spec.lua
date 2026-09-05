local Config = require("gotest.config")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("config", function()
  it("should keep the split as the default", function()
    local opts = Config.setup()

    assert.are.same("split", opts.view.type)
    assert.are.same(15, opts.view.height)
    assert.are.same({ width = 0.8, height = 0.8 }, opts.view.float)
  end)

  it("should accept empty nested options", function()
    local opts = Config.setup({ view = { float = {} }, diagnostics = {} })

    assert.are.same(Config.setup(), opts)
  end)

  it("should merge partial float options", function()
    local opts = Config.setup({ view = { type = "float", float = { width = 60 } } })

    assert.are.same("float", opts.view.type)
    assert.are.same({ width = 60, height = 0.8 }, opts.view.float)
    assert.are.same(15, opts.view.height)
    assert.is.truthy(opts.view.focus_on_fail)
    assert.are.same({ width = 0.8, height = 0.8 }, Config.setup().view.float)
  end)

  it("should leave the float border unset by default", function()
    assert.is.Nil(Config.setup().view.float.border)
  end)

  it("should keep a configured float border", function()
    local opts = Config.setup({ view = { float = { border = "single" } } })

    assert.are.same("single", opts.view.float.border)
  end)
end)
