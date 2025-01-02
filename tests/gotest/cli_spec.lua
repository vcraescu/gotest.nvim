local cli = require("gotest.new_cli")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("gotest cli", function()
  describe("build_gotest_cmd", function()
    describe("with options", function()
      it("cached", function()
        local actual = cli.build_gotest_cmd(
          "./foo/bar/internal/quotation/domain",
          { "TestQuotaGenerator_Generate" },
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
          { "TestQuotaGenerator_Generate" },
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
          { "TestQuotaGenerator_Generate" },
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
        local actual = cli.build_gotest_cmd(nil, { "TestQuotaGenerator_Generate" }, "april with no holidays")
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
        local actual = cli.build_gotest_cmd(nil, { "TestQuotaGenerator_Generate" })
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
        local actual = cli.build_gotest_cmd("./foo/bar/internal/quotation/domain", { "TestQuotaGenerator_Generate" })
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

      it("should fail is path or test_name is missing", function()
        assert.is.error(function()
          cli.build_gotest_cmd("")
        end)
      end)
    end)
  end)

  describe("exec_cmd", function()
    it("should return the error output", function()
      local cmd = { "go", "test" }
      local actual, exit_code = cli.exec_cmd(cmd)
      local expected = {
        "\tto create a module there, run:",
        "\tgo mod init",
      }

      assert.is.equals(1, exit_code)
      assert.is.same(expected[1], actual[2])
      assert.is.same(expected[2], actual[3])
    end)

    it("should return the output", function()
      local cmd = { "go", "test", "-v", "-json", "./...", "-run=TestSum" }
      local actual, actual_exit_code = cli.exec_cmd(cmd, "./tests/gotest/fixtures/cli")
      local expected = vim.fn.json_decode([[
        [
          {
            "Time": "2025-01-01T11:12:14.387499+02:00",
            "Action": "start",
            "Package": "cli"
          },
          {
            "Time": "2025-01-01T11:12:14.5859+02:00",
            "Action": "run",
            "Package": "cli",
            "Test": "TestSum"
          },
          {
            "Time": "2025-01-01T11:12:14.58605+02:00",
            "Action": "output",
            "Package": "cli",
            "Test": "TestSum",
            "Output": "=== RUN   TestSum\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586084+02:00",
            "Action": "run",
            "Package": "cli",
            "Test": "TestSum/success"
          },
          {
            "Time": "2025-01-01T11:12:14.586093+02:00",
            "Action": "output",
            "Package": "cli",
            "Test": "TestSum/success",
            "Output": "=== RUN   TestSum/success\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586111+02:00",
            "Action": "run",
            "Package": "cli",
            "Test": "TestSum/fail"
          },
          {
            "Time": "2025-01-01T11:12:14.586128+02:00",
            "Action": "output",
            "Package": "cli",
            "Test": "TestSum/fail",
            "Output": "=== RUN   TestSum/fail\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586134+02:00",
            "Action": "output",
            "Package": "cli",
            "Test": "TestSum/fail",
            "Output": "    sum_test.go:31: sum() = 10, want 20\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586165+02:00",
            "Action": "output",
            "Package": "cli",
            "Test": "TestSum",
            "Output": "--- FAIL: TestSum (0.00s)\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586175+02:00",
            "Action": "output",
            "Package": "cli",
            "Test": "TestSum/success",
            "Output": "    --- PASS: TestSum/success (0.00s)\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586186+02:00",
            "Action": "pass",
            "Package": "cli",
            "Test": "TestSum/success",
            "Elapsed": 0
          },
          {
            "Time": "2025-01-01T11:12:14.586199+02:00",
            "Action": "output",
            "Package": "cli",
            "Test": "TestSum/fail",
            "Output": "    --- FAIL: TestSum/fail (0.00s)\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586203+02:00",
            "Action": "fail",
            "Package": "cli",
            "Test": "TestSum/fail",
            "Elapsed": 0
          },
          {
            "Time": "2025-01-01T11:12:14.586208+02:00",
            "Action": "fail",
            "Package": "cli",
            "Test": "TestSum",
            "Elapsed": 0
          },
          {
            "Time": "2025-01-01T11:12:14.586211+02:00",
            "Action": "output",
            "Package": "cli",
            "Output": "FAIL\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586779+02:00",
            "Action": "output",
            "Package": "cli",
            "Output": "FAIL\tcli\t0.199s\n"
          },
          {
            "Time": "2025-01-01T11:12:14.586813+02:00",
            "Action": "fail",
            "Package": "cli",
            "Elapsed": 0.199
          }
        ]
      ]])

      assert.is.equals(1, actual_exit_code)
      assert.is.truthy(#actual > 0)

      for index, actual_line in ipairs(actual) do
        local a = vim.fn.json_decode(actual_line)
        local e = expected[index]

        assert.is.equals(e.Action, a.Action)
        assert.is.equals(e.Package, a.Package)
        assert.is.equals(e.Test, a.Test)
      end
    end)
  end)
end)
