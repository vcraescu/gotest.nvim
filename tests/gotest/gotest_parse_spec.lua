local parse = require("gotest.gotest_parse")
local utils = require("tests.gotest.utils")

utils.setup_test()

local function sort_tests(tests)
  return vim.fn.sort(tests, function(a, b)
    if a.name < b.name then
      return -1
    elseif a.name > b.name then
      return 1
    end

    return 0
  end)
end

describe("test output parse", function()
  -- it("should return an error if nil is passed", function()
  --   assert.is.error(function()
  --     --- @diagnostic disable-next-line: param-type-mismatch
  --     parse(nil)
  --   end)
  -- end)
  --
  -- it("should parse empty output", function()
  --   local actual = parse({})
  --
  --   assert.are.same({}, actual)
  -- end)
  --
  -- it("should return an error if build failed", function()
  --   local lines = utils.load_fixture("/gotest_parse/build_failed_output.json")
  --
  --   assert.is.error(function()
  --     parse(lines)
  --   end)
  -- end)
  --
  -- it("should parse test output from 'go test ./module/name'", function()
  --   local lines = utils.load_fixture("/gotest_parse/single_file_output.json")
  --   local actual = parse(lines)
  --   local expected = vim.fn.json_decode([[
  --     [
  --       { "output": [], "name": "TestQuota_AddHours", "failed": true },
  --       {
  --         "output": [],
  --         "parent": "TestQuota_AddHours",
  --         "name": "TestQuota_AddHours/add_hours_more_than_a_day",
  --         "real_name": "add hours more than a day"
  --       },
  --       {
  --         "file": "/Users/john/Projects/foo/bar/internal/quotation/domain/quota_test.go",
  --         "output": [
  --           "        \tError:      \tNot equal:",
  --           "        \t            \texpected: []domain.QuotaRow{domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:32}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:40}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:16.3}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:t",
  --           "ime.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:20}}",
  --           "        \t            \tactual  : []domain.QuotaRow{domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:32}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:8}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:40}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:16.3}, domain.QuotaRow{Title:\"\", Range:domain.Range{Start:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), End:t",
  --           "ime.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)}, Hours:23}}",
  --           "        \t            \t",
  --           "        \t            \tDiff:",
  --           "        \t            \t--- Expected",
  --           "        \t            \t+++ Actual",
  --           "        \t            \t@@ -95,3 +95,3 @@",
  --           "        \t            \t   },",
  --           "        \t            \t-  Hours: (float64) 20",
  --           "        \t            \t+  Hours: (float64) 23",
  --           "        \t            \t  }"
  --         ],
  --         "parent": "TestQuota_AddHours",
  --         "name": "TestQuota_AddHours/add_hours_less_than_a_day",
  --         "real_name": "add hours less than a day",
  --         "lineno": 254,
  --         "failed": true
  --       },
  --       {
  --         "output": [],
  --         "parent": "TestQuota_AddHours",
  --         "name": "TestQuota_AddHours/6_holidays",
  --         "real_name": "6 holidays"
  --       },
  --       {
  --         "output": [],
  --         "parent": "TestQuota_AddHours",
  --         "name": "TestQuota_AddHours/subtract_hours_less_than_a_day",
  --         "real_name": "subtract hours less than a day"
  --       }
  --     ]
  --   ]])
  --
  --   actual = sort_tests(actual)
  --   expected = sort_tests(expected)
  --
  --   assert.are.same(expected, actual)
  -- end)

  it("should parse test output from 'go test ./...'", function()
    local lines = utils.load_fixture("/gotest_parse/multiple_packages_output.json")
    local actual = parse(lines)
    local expected = vim.fn.json_decode([[
      [
        {
          "output": [],
          "parent": "TestQuotaGenerator_Generate",
          "name": "TestQuotaGenerator_Generate/december_with_no_holidays",
          "real_name": "december with no holidays",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestRange_BusinessWeeks",
          "name": "TestRange_BusinessWeeks/weekend",
          "real_name": "weekend",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestQuota_AddHours",
          "name": "TestQuota_AddHours/add_hours_more_than_a_day",
          "real_name": "add hours more than a day",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestQuotaGenerator_Generate",
          "name": "TestQuotaGenerator_Generate/december_with_6_holidays",
          "real_name": "december with 6 holidays",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestQuota_AddHours",
          "name": "TestQuota_AddHours/subtract_hours_less_than_a_day",
          "real_name": "subtract hours less than a day",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestRange_BusinessWeeks",
          "name": "TestRange_BusinessWeeks/april",
          "real_name": "april",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestRange_BusinessWeeks",
          "name": "TestRange_BusinessWeeks/no_end_date",
          "real_name": "no end date",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": ["oooooooooooooooooooooooooooooooooooooooooooooooo"],
          "parent": "TestQuotaGenerator_Generate",
          "name": "TestQuotaGenerator_Generate/april_with_no_holidays",
          "real_name": "april with no holidays",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestQuota_AddHours",
          "name": "TestQuota_AddHours/6_holidays",
          "real_name": "6 holidays",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestRange_BusinessWeeks",
          "name": "TestRange_BusinessWeeks/first_week_of_april",
          "real_name": "first week of april",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestRange_BusinessWeeks",
          "name": "TestRange_BusinessWeeks/one_day_of_the_week",
          "real_name": "one day of the week",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "parent": "TestRange_BusinessWeeks",
          "name": "TestRange_BusinessWeeks/march",
          "real_name": "march",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "module": "github.com/foo/bar/internal/quotation/domain",
          "name": "TestQuota_AddHours",
          "failed": true
        },
        {
          "output": [],
          "module": "github.com/foo/bar/internal/quotation/domain",
          "name": "TestQuotaGenerator_Generate"
        },
        {
          "output": [],
          "parent": "TestQuotaGenerator_Generate",
          "name": "TestQuotaGenerator_Generate/september_with_7_holidays",
          "real_name": "september with 7 holidays",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "output": [],
          "module": "github.com/foo/bar/internal/quotation/domain",
          "name": "TestRange_BusinessWeeks"
        },
        {
          "output": [],
          "parent": "TestRange_BusinessWeeks",
          "name": "TestRange_BusinessWeeks/no_start_and_end_date",
          "real_name": "no start and end date",
          "module": "github.com/foo/bar/internal/quotation/domain"
        },
        {
          "file": "/Users/john/Projects/foo/bar/internal/quotation/domain/quota_test.go",
          "output": [
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
          "parent": "TestQuota_AddHours",
          "name": "TestQuota_AddHours/add_hours_less_than_a_day",
          "module": "github.com/foo/bar/internal/quotation/domain",
          "real_name": "add hours less than a day",
          "failed": true,
          "lineno": 256
        }
      ]
    ]])

    actual = sort_tests(actual)
    expected = sort_tests(expected)

    print(vim.inspect(actual))
    -- assert.are.same(expected, actual)
  end)
end)
