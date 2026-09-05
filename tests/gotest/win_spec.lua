local Win = require("gotest.win")
local utils = require("tests.gotest.utils")

utils.setup_test()

--- @type table<string, string[]>
local BORDER_CHARS = {
  single = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
  double = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
  rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
}

describe("win", function()
  local windows
  local original_options

  local function new_win(opts)
    local win = Win.new(opts)
    table.insert(windows, win)
    return win
  end

  before_each(function()
    windows = {}
    original_options = {
      columns = vim.o.columns,
      lines = vim.o.lines,
      cmdheight = vim.o.cmdheight,
      winborder = vim.o.winborder,
    }
    vim.o.columns = 100
    vim.o.lines = 40
    vim.o.cmdheight = 1
    vim.o.winborder = "rounded"
  end)

  after_each(function()
    for _, win in ipairs(windows) do
      win:close()
      vim.api.nvim_buf_delete(win._buf, { force = true })
    end
    vim.cmd("silent only")
    vim.o.columns = original_options.columns
    vim.o.lines = original_options.lines
    vim.o.cmdheight = original_options.cmdheight
    vim.o.winborder = original_options.winborder
  end)

  it("should open a bottom split by default", function()
    vim.cmd.vsplit()
    local current_win = vim.api.nvim_get_current_win()
    local win = new_win()
    win:set_text("output")

    assert.are.same("", vim.api.nvim_win_get_config(win._win).relative)
    assert.are.same(15, vim.api.nvim_win_get_height(win._win))
    assert.are.same(vim.o.columns, vim.api.nvim_win_get_width(win._win))
    assert.are.same(current_win, vim.api.nvim_get_current_win())
    assert.is.truthy(vim.wo[win._win].winfixheight)
    for _, other_win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if other_win ~= win._win then
        assert.is.truthy(vim.api.nvim_win_get_position(other_win)[1] < vim.api.nvim_win_get_position(win._win)[1])
      end
    end
  end)

  it("should use the configured split height", function()
    local win = new_win({ height = 8 })
    win:set_text("output")

    assert.are.same(8, vim.api.nvim_win_get_height(win._win))
  end)

  it("should report whether the window is open", function()
    local win = new_win({ type = "float" })

    assert.is.falsy(win:is_open())

    win:set_text("output")
    assert.is.truthy(win:is_open())

    win:close()
    assert.is.falsy(win:is_open())
  end)

  it("should close the window when Esc is pressed", function()
    local win = new_win({ type = "float" })
    win:set_text("output")

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(100)

    assert.is.falsy(win:is_open())
  end)

  it("should run the toggle callback when Esc is pressed", function()
    local toggled = false
    local win = new_win({
      type = "float",
      on_toggle = function()
        toggled = true
      end,
    })
    win:set_text("output")

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(100)

    assert.is.equal(true, toggled)
  end)

  it("should center a float with the default sizes", function()
    local layout = vim.fn.winlayout()
    local win = new_win({ type = "float" })
    win:set_text("output")
    local config = vim.api.nvim_win_get_config(win._win)

    assert.are.same("editor", config.relative)
    assert.are.same(80, config.width)
    assert.are.same(31, config.height)
    assert.are.same(10, config.col)
    assert.are.same(4, config.row)
    assert.are.same(BORDER_CHARS.rounded, config.border)
    assert.are.same(layout, vim.fn.winlayout())
  end)

  it("should focus the float when it opens", function()
    local win = new_win({ type = "float" })
    win:set_text("output")

    assert.are.same(win._win, vim.api.nvim_get_current_win())
  end)

  it("should use the winborder option by default", function()
    local win = new_win({ type = "float" })
    win:set_text("output")

    assert.are.same(BORDER_CHARS.rounded, vim.api.nvim_win_get_config(win._win).border)
  end)

  it("should follow the winborder option when it changes", function()
    vim.o.winborder = "double"
    local win = new_win({ type = "float" })
    win:set_text("output")

    assert.are.same(BORDER_CHARS.double, vim.api.nvim_win_get_config(win._win).border)
  end)

  it("should use the configured border over the winborder option", function()
    vim.o.winborder = "single"
    local win = new_win({ type = "float", float = { border = "double" } })
    win:set_text("output")

    assert.are.same(BORDER_CHARS.double, vim.api.nvim_win_get_config(win._win).border)
  end)

  it("should use columns and rows for absolute sizes", function()
    local win = new_win({ type = "float", float = { width = 60, height = 20 } })
    win:set_text("output")
    local config = vim.api.nvim_win_get_config(win._win)

    assert.are.same(60, config.width)
    assert.are.same(20, config.height)
    assert.are.same(20, config.col)
    assert.are.same(9, config.row)
  end)

  it("should resolve width and height independently", function()
    local win = new_win({ type = "float", float = { width = 0.5, height = 10 } })
    win:set_text("output")
    local config = vim.api.nvim_win_get_config(win._win)

    assert.are.same(50, config.width)
    assert.are.same(10, config.height)
  end)

  it("should retain the default height with a width override", function()
    local win = new_win({ type = "float", float = { width = 60 } })
    win:set_text("output")

    assert.are.same(31, vim.api.nvim_win_get_height(win._win))
  end)

  it("should exclude command rows from the available height", function()
    vim.o.cmdheight = 4
    local win = new_win({ type = "float", float = { height = 0.5 } })
    win:set_text("output")
    local config = vim.api.nvim_win_get_config(win._win)

    assert.are.same(18, config.height)
    assert.are.same(9, config.row)
  end)

  it("should limit large sizes to the available screen", function()
    local win = new_win({ type = "float", float = { width = 1000, height = 1000 } })
    win:set_text("output")
    local config = vim.api.nvim_win_get_config(win._win)

    assert.are.same(100, config.width)
    assert.are.same(39, config.height)
    assert.are.same(0, config.col)
    assert.are.same(0, config.row)
  end)

  it("should round absolute sizes down", function()
    local win = new_win({ type = "float", float = { width = 60.9, height = 20.9 } })
    win:set_text("output")

    assert.are.same(60, vim.api.nvim_win_get_width(win._win))
    assert.are.same(20, vim.api.nvim_win_get_height(win._win))
  end)

  it("should use at least one column and row for small fractions", function()
    local win = new_win({ type = "float", float = { width = 0.001, height = 0.001 } })
    win:set_text("output")

    assert.are.same(1, vim.api.nvim_win_get_width(win._win))
    assert.are.same(1, vim.api.nvim_win_get_height(win._win))
  end)

  it("should treat one as an absolute size without a winbar error", function()
    local win = new_win({ type = "float", float = { width = 1, height = 1 } })
    vim.v.errmsg = ""
    win:set_title("go test")
    win:set_text("output")

    assert.are.same(1, vim.api.nvim_win_get_width(win._win))
    assert.are.same(1, vim.api.nvim_win_get_height(win._win))
    assert.are.same("", vim.v.errmsg)
  end)

  it("should reject invalid float sizes", function()
    for _, size in ipairs({ 0, -1, "80%", math.huge, 0 / 0 }) do
      for _, dimension in ipairs({ "width", "height" }) do
        local win = new_win({ type = "float", float = { [dimension] = size } })
        assert.is.error(function()
          win:set_text("output")
        end)
      end
    end
  end)

  it("should reuse the float and retain output after closing", function()
    local win = new_win({ type = "float" })
    win:set_text("first output")
    local win_id = win._win
    win:set_title("go test", { total = 2, passed = 1, failed = 1, skipped = 0 })
    win:set_text("second output")

    assert.are.same(win_id, win._win)
    assert.is.truthy(vim.wo[win_id].winbar:find("1/2 passed", 1, true))
    assert.are.same({ "second output" }, vim.api.nvim_buf_get_lines(win._buf, 0, -1, false))

    win:focus()
    assert.are.same(win_id, vim.api.nvim_get_current_win())
    win:close()
    assert.is.falsy(vim.api.nvim_win_is_valid(win_id))
    win:focus()

    assert.are.same("editor", vim.api.nvim_win_get_config(win._win).relative)
    assert.are.same({ "second output" }, vim.api.nvim_buf_get_lines(win._buf, 0, -1, false))
  end)

  it("should use the current screen size when the float opens again", function()
    local win = new_win({ type = "float" })
    win:set_text("output")
    win:close()
    vim.o.columns = 120
    vim.o.lines = 50
    win:set_text("output")

    assert.are.same(96, vim.api.nvim_win_get_width(win._win))
    assert.are.same(39, vim.api.nvim_win_get_height(win._win))
  end)
end)
