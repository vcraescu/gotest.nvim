local ts = require("gotest.ts")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("ts", function()
  describe("get_current_func_name", function()
    it("should return current function name if inside block", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 22, 5 })
      local actual = ts.get_current_func_name(bufnr)

      assert.is.equals("TestSum", actual)
    end)

    it("should return current function name if inside function", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 10, 5 })
      local actual = ts.get_current_func_name(bufnr)

      assert.is.equals("TestSum", actual)
    end)

    it("should return nil if outside function", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 4, 5 })
      local actual = ts.get_current_func_name(bufnr)

      assert.is.Nil(actual)
    end)
  end)

  describe("get_current_table_test_name", function()
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

  describe("get_current_test", function()
    it("should return test name and table test name", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 18, 5 })

      local actual_test_name, actual_table_test_name = ts.get_current_test(bufnr)
      assert.is.equals("TestSum", actual_test_name)
      assert.is.equals("success", actual_table_test_name)
    end)

    it("should return test name and sub test name", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 48, 5 })

      local actual_test_name, actual_sub_test_name = ts.get_current_test(bufnr)
      assert.is.equals("TestSum2", actual_test_name)
      assert.is.equals("fail", actual_sub_test_name)
    end)

    it("should return test name", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 44, 5 })

      local actual_test_name, actual_sub_test_name = ts.get_current_test(bufnr)
      assert.is.equals("TestSum2", actual_test_name)
      assert.is.Nil(actual_sub_test_name)
    end)

    it("should return nil", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 1, 5 })

      local actual = ts.get_current_test(bufnr)
      assert.is.Nil(actual)
    end)
  end)
end)
