local M = {}

---@class gotest.Config.view
---@field focus_on_fail boolean
---@field focus_on_success boolean
---@field show_on_fail boolean
---@field show_on_success boolean
---@field height number

---@class gotest.Config.diagnostics
---@field enabled boolean

---@class gotest.Config
---@field view gotest.Config.view
---@field timeout number
---@field disable_test_cache boolean
---@field diagnostics gotest.Config.diagnostics

---@class gotest.Parser
---@field _lines string[]?
---@field _results gotest.GoTestResult[]

---@class gotest.GoTestResult.Action
---@field PASS string
---@field SKIP string
---@field FAIL string
---@field BUILD_FAIL string

---@class gotest.GoTestResult
---@field Action? string
---@field Package? string
---@field Test? string
---@field Output string

---@class gotest.GoTestStats
---@field total number
---@field passed number
---@field failed number
---@field skipped number

---@class gotest.Diagnostics

---@class gotest.Highlights
---@field FAILED string
---@field PASSED string
---@field SKIPPED string
---@field IGNORED string

---@class gotest.Cli.opts
---@field cached? boolean
---@field timeout? number

---@class gotest.Cli.command
---@field cmd string[]
---@field cwd? string

---@class gotest.TestFile
---@field bufnr number?

---@class gotest.View
---@field opts gotest.Config.view
---@field _win gotest.Win

---@class gotest.win.highlight
---@field higroup string
---@field start number[]
---@field finish number[]

---@class gotest.Win
---@field opts gotest.win.Config
---@field _buf number
---@field _win number
---@field _ns number
---@field _title string
---@field _text string[]
---@field _highlights gotest.win.highlight[]

---@class gotest.win.Config
---@field height? number
---@field keys? table<string, string>

---@class gotest.Api
---@field opts gotest.Config
---@field _view gotest.View
---@field _cmd string[]
---@field _bufnr integer

return M
