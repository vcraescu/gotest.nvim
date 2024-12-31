local cli = require("gotest.new_cli")

describe("gotest cli", function()
  describe("build_gotest_cmd", function()
    describe("with options", function()
      it("cached", function()
        local actual = cli.build_gotest_cmd(
          "./foo/bar/internal/quotation/domain",
          "TestQuotaGenerator_Generate",
          "april with no holidays",
          { cached = true }
        )
        local expected = {
          "go",
          "test",
          "-v",
          "-json",
          "./foo/bar/internal/quotation/domain",
          [[-run=^\QTestQuotaGenerator_Generate\E$/^\Qapril with no holidays\E$]],
        }

        assert.are.same(expected, actual)
      end)

      it("timeout and cache", function()
        local actual = cli.build_gotest_cmd(
          "./foo/bar/internal/quotation/domain",
          "TestQuotaGenerator_Generate",
          "april with no holidays",
          { cached = true, timeout = 30 }
        )
        local expected = {
          "go",
          "test",
          "-v",
          "-json",
          "-timeout=30s",
          "./foo/bar/internal/quotation/domain",
          [[-run=^\QTestQuotaGenerator_Generate\E$/^\Qapril with no holidays\E$]],
        }

        assert.are.same(expected, actual)
      end)
    end)

    describe("with default options", function()
      it("should build with path, test and subtest", function()
        local actual = cli.build_gotest_cmd(
          "./foo/bar/internal/quotation/domain",
          "TestQuotaGenerator_Generate",
          "april with no holidays"
        )
        local expected = {
          "go",
          "test",
          "-v",
          "-json",
          "-count=1",
          "./foo/bar/internal/quotation/domain",
          [[-run=^\QTestQuotaGenerator_Generate\E$/^\Qapril with no holidays\E$]],
        }

        assert.are.same(expected, actual)
      end)

      it("should build with test and subtest", function()
        local actual = cli.build_gotest_cmd(nil, "TestQuotaGenerator_Generate", "april with no holidays")
        local expected = {
          "go",
          "test",
          "-v",
          "-json",
          "-count=1",
          [[-run=^\QTestQuotaGenerator_Generate\E$/^\Qapril with no holidays\E$]],
        }

        assert.are.same(expected, actual)
      end)

      it("should build with test", function()
        local actual = cli.build_gotest_cmd(nil, "TestQuotaGenerator_Generate")
        local expected = {
          "go",
          "test",
          "-v",
          "-json",
          "-count=1",
          [[-run=^\QTestQuotaGenerator_Generate\E$]],
        }

        assert.are.same(expected, actual)
      end)

      it("should build with path and test", function()
        local actual = cli.build_gotest_cmd("./foo/bar/internal/quotation/domain", "TestQuotaGenerator_Generate")
        local expected = {
          "go",
          "test",
          "-v",
          "-json",
          "-count=1",
          "./foo/bar/internal/quotation/domain",
          [[-run=^\QTestQuotaGenerator_Generate\E$]],
        }

        assert.are.same(expected, actual)
      end)

      it("should build with path", function()
        local actual = cli.build_gotest_cmd("./foo/bar/internal/quotation/domain/foo_test.go")
        local expected = {
          "go",
          "test",
          "-v",
          "-json",
          "-count=1",
          "./foo/bar/internal/quotation/domain/foo_test.go",
        }

        assert.are.same(expected, actual)
      end)

      it("should fail if test is missing and subtest is set", function()
        assert.is.error(function()
          cli.build_gotest_cmd(nil, nil, "april with no holidays")
        end)
      end)

      it("shoudl fail is path or test_name is missing", function()
        assert.is.error(function()
          cli.build_gotest_cmd("", "")
        end)
      end)
    end)
  end)
end)
