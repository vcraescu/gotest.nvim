local TestFile = require("gotest.test_file")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("test_file", function()
  describe("get_current_test", function()
    it("should return the current test name when the cursor is inside a test function", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 10, 5 })

      local actual = TestFile.new(bufnr):get_current_test()

      assert.is.same({ "TestSum" }, actual)
    end)

    it("should return the table test name when the cursor is inside a table test case", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 19, 5 })

      local test_names, subtest_name = TestFile.new(bufnr):get_current_test()

      assert.is.same({ "TestSum" }, test_names)
      assert.is.equal("success", subtest_name)
    end)

    it("should return nil when the cursor is outside a test function", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")
      vim.api.nvim_win_set_cursor(0, { 1, 1 })

      local test_names, subtest_name = TestFile.new(bufnr):get_current_test()

      assert.is.Nil(test_names)
      assert.is.Nil(subtest_name)
    end)
  end)

  describe("has_tests", function()
    it("should return true when the file has test functions", function()
      local bufnr = utils.load_buf_fixture("/ts/sum_test.go", "go")

      assert.is.equal(true, TestFile.new(bufnr):has_tests())
    end)

    it("should return false when the file has no test functions", function()
      local bufnr = utils.load_buf_fixture("/ts/sum.go", "go")

      assert.is.equal(false, TestFile.new(bufnr):has_tests())
    end)
  end)
end)
