local ts = require("gotest.ts")
local utils = require("tests.gotest.utils")

utils.setup_test()

-- hack latest nvim treestitter get_node_text bug
-- TODO remove this after nvim-treesitter is fixed
local nvim11 = vim.fn.has("nvim-0.11") == 1

describe("ts", function()
  describe("get_current_test_func_name", function()
    it("should return current function name if inside block", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 22, 5 })
      local actual = ts.get_current_test_func_name(bufnr)

      assert.is.equals("TestSum", actual)
    end)

    it("should return current function name if inside function", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 10, 5 })
      local actual = ts.get_current_test_func_name(bufnr)

      assert.is.equals("TestSum", actual)
    end)

    it("should return nil if outside function", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 4, 5 })
      local actual = ts.get_current_test_func_name(bufnr)

      assert.is.Nil(actual)
    end)
  end)

  describe("get_current_table_test_name", function()
    if nvim11 then
      assert.is.equals(1, 1)
      return
    end

    it("should return table name", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 19, 5 })
      local actual = ts.get_current_table_test_name(bufnr)

      assert.is.equals("success", actual)

      vim.api.nvim_win_set_cursor(0, { 24, 5 })
      actual = ts.get_current_table_test_name(bufnr)

      assert.is.equals("fail", actual)
    end)

    it("should return nil if not on table test case", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 30, 5 })
      local actual = ts.get_current_table_test_name(bufnr)

      assert.is.Nil(actual)

      vim.api.nvim_win_set_cursor(0, { 27, 5 })
      actual = ts.get_current_table_test_name(bufnr)

      assert.is.Nil(actual)
    end)
  end)

  describe("get_current_sub_test_name", function()
    it("should return sub test name", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 41, 5 })
      local actual = ts.get_current_sub_test_name(bufnr)

      assert.is.equals("success", actual)

      vim.api.nvim_win_set_cursor(0, { 47, 5 })
      actual = ts.get_current_sub_test_name(bufnr)

      assert.is.equals("fail", actual)
    end)

    it("should return nil if not on sub test case", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 44, 5 })
      local actual = ts.get_current_sub_test_name(bufnr)

      assert.is.Nil(actual)
    end)
  end)

  describe("get_func_def_line_no", function()
    it("should return function definition line number", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")

      local actual = ts.get_func_def_line_no(bufnr, "TestSum")
      assert.is.equals(4, actual)

      actual = ts.get_func_def_line_no(bufnr, "TestSum2")
      assert.is.equals(36, actual)
    end)

    it("should return nil if function is not found", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")

      local actual = ts.get_func_def_line_no(bufnr, "Foobar")
      assert.is.Nil(actual)
    end)
  end)
end)
