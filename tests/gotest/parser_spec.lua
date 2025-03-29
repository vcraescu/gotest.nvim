local Parser = require("gotest.parser")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("test output parse", function()
  it("should return an error if nil is passed", function()
    assert.is.error(function()
      --- @diagnostic disable-next-line: param-type-mismatch
      Parser.new(nil)
    end)
  end)

  it("should parse empty output", function()
    assert.are.same({}, Parser.new({}):parse())
  end)

  it("should return the output if build failed", function()
    local lines = utils.load_fixture("/gotest_parse/build_failed_output.json")

    local actual = Parser.new(lines):parse()
    local expected = {
      {
        output = {
          "# github.com/foo/bar/internal/quotation/domain_test [github.com/foo/bar/internal/quotation/domain.test]",
        },
      },
      { output = { "internal/quotation/domain/quota_test.go:23:2: undefined: ddd" } },
    }
    assert.is.not_nil(actual)
    assert.are.same(expected, actual)
  end)

  it("should parse test output from 'go test ./module/name'", function()
    local lines = utils.load_fixture("/gotest_parse/single_file_output.json")
    local actual = Parser.new(lines):parse()
    local expected = vim.fn.json_decode([[
      [
        {
          "name": "TestQuota_AddHours",
          "failed": true,
          "ignored": false,
          "tests": [
            {
              "name": "6_holidays",
              "real_name": "6 holidays",
              "passed": true,
              "ignored": false
            },
            {
              "file": "/Users/john/Projects/foo/bar/internal/quotation/domain/quota_test.go",
              "output": [
                "        \tError Trace:\t/Users/john/Projects/foo/bar/internal/quotation/domain/quota_test.go:254",
                "        \tError:      \tNot equal:",
                "        \t            \texpected: []domain.QuotaRow{domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:32}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:40}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:16.3}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:t",
                "ime.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:20}}",
                "        \t            \tactual  : []domain.QuotaRow{domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:32}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:40}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:16.3}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:t",
                "ime.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:23}}",
                "        \t            \t",
                "        \t            \tDiff:",
                "        \t            \t--- Expected",
                "        \t            \t+++ Actual",
                "        \t            \t@@ -95,3 +95,3 @@",
                "        \t            \t   },",
                "        \t            \t-  Hours: (float64) 20",
                "        \t            \t+  Hours: (float64) 23",
                "        \t            \t  }"
              ],
              "name": "add_hours_less_than_a_day",
              "real_name": "add hours less than a day",
              "lineno": 254,
              "failed": true,
              "ignored": false
            },
            {
              "name": "add_hours_more_than_a_day",
              "real_name": "add hours more than a day",
              "passed": true,
              "ignored": false
            },
            {
              "name": "subtract_hours_less_than_a_day",
              "real_name": "subtract hours less than a day",
              "passed": true,
              "ignored": false
            }
          ]
        }
      ]
    ]])

    assert.are.same(expected, actual)
  end)

  it("should parse test output from 'go test ./...'", function()
    local lines = utils.load_fixture("/gotest_parse/multiple_packages_output.json")
    local actual = Parser.new(lines):parse()
    local expected = vim.fn.json_decode([[
      [
        {
          "module": "github.com/foo/bar/internal/quotation/domain",
          "name": "TestQuotaGenerator_Generate",
          "passed": true,
          "ignored": false,
          "tests": [
            {
              "output": ["oooooooooooooooooooooooooooooooooooooooooooooooo"],
              "name": "april_with_no_holidays",
              "real_name": "april with no holidays",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "december_with_6_holidays",
              "real_name": "december with 6 holidays",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "december_with_no_holidays",
              "real_name": "december with no holidays",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "september_with_7_holidays",
              "real_name": "september with 7 holidays",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            }
          ]
        },
        {
          "module": "github.com/foo/bar/internal/quotation/domain",
          "name": "TestQuota_AddHours",
          "failed": true,
          "ignored": false,
          "tests": [
            {
              "name": "6_holidays",
              "real_name": "6 holidays",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "file": "/Users/john/Projects/foo/bar/internal/quotation/domain/quota_test.go",
              "output": [
                "        \tError Trace:\t/Users/john/Projects/foo/bar/internal/quotation/domain/quota_test.go:256",
                "        \tError:      \tNot equal:",
                "        \t            \texpected: []domain.QuotaRow{domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:32}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:40}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:16.3}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:t",
                "ime.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:20}}",
                "        \t            \tactual  : []domain.QuotaRow{domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:32}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:40}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:16.3}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:t",
                "ime.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:23}}",
                "        \t            \t",
                "        \t            \tDiff:",
                "        \t            \t--- Expected",
                "        \t            \t+++ Actual",
                "        \t            \t@@ -95,3 +95,3 @@",
                "        \t            \t   },",
                "        \t            \t-  Hours: (float64) 20",
                "        \t            \t+  Hours: (float64) 23",
                "        \t            \t  }"
              ],
              "name": "add_hours_less_than_a_day",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "real_name": "add hours less than a day",
              "failed": true,
              "lineno": 256,
              "ignored": false
            },
            {
              "name": "add_hours_more_than_a_day",
              "real_name": "add hours more than a day",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "subtract_hours_less_than_a_day",
              "real_name": "subtract hours less than a day",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            }
          ]
        },
        {
          "module": "github.com/foo/bar/internal/quotation/domain",
          "name": "TestRange_BusinessWeeks",
          "passed": true,
          "ignored": false,
          "tests": [
            {
              "name": "april",
              "real_name": "april",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "first_week_of_april",
              "real_name": "first week of april",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "march",
              "real_name": "march",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "no_end_date",
              "real_name": "no end date",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "no_start_and_end_date",
              "real_name": "no start and end date",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "one_day_of_the_week",
              "real_name": "one day of the week",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            },
            {
              "name": "weekend",
              "real_name": "weekend",
              "module": "github.com/foo/bar/internal/quotation/domain",
              "passed": true,
              "ignored": false
            }
          ]
        }
      ]
    ]])

    assert.are.same(expected, actual)
  end)
end)
