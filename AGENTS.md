# AGENTS.md

## Project Overview

`gotest.nvim` is a Neovim plugin for running Go tests from within the editor. It uses Tree-sitter to
find the test under the cursor, builds a `go test -v -json` command, parses the output, and renders
results in an interactive tree view with diagnostics.

---

## Commands

### Format
```bash
make fmt
# runs: stylua lua/ tests/gotest/*.lua
```

### Lint
```bash
make lint
# runs: luacheck lua/ tests/gotest/*.lua --globals vim
```

### Test (all)
```bash
make test
# runs: nvim --headless --noplugin -u scripts/minimal_init.lua \
#   -c "PlenaryBustedDirectory tests/gotest { minimal_init = './scripts/minimal_init.lua', sequential = true }"
```

### Test (single file)
```bash
nvim --headless --noplugin -u scripts/minimal_init.lua \
  -c "PlenaryBustedFile tests/gotest/cli_spec.lua { minimal_init = './scripts/minimal_init.lua' }"
```

### Install Tree-sitter Go parser (required before first test run)
```bash
nvim --headless -u scripts/minimal_init.lua -i NONE \
  -c "lua require('nvim-treesitter.install').install({'go'}, true)" -c "q"
```

### CI
Tests run on `ubuntu-22.04` against Neovim `nightly` and `v0.11.0`. See `.github/workflows/ci.yml`.
The CI installs the Go Tree-sitter parser before running `make test`.

---

## Project Structure

```
lua/gotest/
  init.lua          # Entry point: setup(), user command registration
  config.lua        # Default config, vim.tbl_deep_extend merge, diagnostic namespace
  api.lua           # Orchestrator: test_nearest(), test_retry(), _run_tests()
  cli.lua           # go test command builder + async jobstart executor
  parser.lua        # go test -json output parser -> GoTestNode[]
  ts.lua            # Tree-sitter queries: test name at cursor, func line numbers
  test_file.lua     # Buffer abstraction: is_test(), get_dir(), get_current_test()
  diagnostics.lua   # vim.diagnostic integration for failed tests
  notify.lua        # nvim_echo wrappers with [gotest] prefix
  win.lua           # Reusable split window + buffer abstraction
  unique_id.lua     # ID generator (hrtime + random)
  view/
    view.lua        # High-level view: render_raw()

tests/gotest/
  cli_spec.lua      # CLI command building and exec tests
  parser_spec.lua   # go test JSON output parsing tests
  ts_spec.lua       # Tree-sitter query function tests
  utils.lua         # Test helpers: load_fixture(), load_buf_fixture()
  fixtures/         # JSON and Go source fixture files
```

---

## Code Style

### Formatter
`stylua` with the following config (`stylua.toml`):
- `indent_type = "Spaces"`, `indent_width = 2`
- `column_width = 120`
- `line_endings = "Unix"`
- `quote_style = "AutoPreferDouble"`

### Module Structure
Every module follows this pattern exactly:
```lua
local M = {}
-- ... functions ...
return M
```

Constructors use `setmetatable` with `__index = M`:
```lua
function M.new(opts)
  return setmetatable({ opts = opts }, { __index = M })
end
```

### Naming Conventions
- **Local variables and function parameters**: `snake_case`
- **`require()` results**: `PascalCase` matching the conceptual class name:
  ```lua
  local Cli      = require("gotest.cli")
  local Notify   = require("gotest.notify")
  local TestFile = require("gotest.test_file")
  local Parser   = require("gotest.parser")
  ```
- **Private instance fields and methods**: prefixed with `_`:
  ```lua
  self._bufnr, self._cmd, self._view
  M:_run_tests(), M:_create_win()
  ```
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Type names in annotations**: `PascalCase` with `gotest.` namespace prefix
- **Files**: `snake_case.lua`

### Imports
All `require` calls go at the top of the file, except for lazy/deferred requires used inside
functions to avoid circular dependencies:
```lua
-- top-level (eager)
local Cli = require("gotest.cli")
```

### Type Annotations
Use EmmyLua/LuaLS style. Two styles exist across the codebase — use whichever the file already uses:
- Compact (`---@`) in simpler modules: `init.lua`, `config.lua`, `api.lua`, `cli.lua`, `ts.lua`
- Spaced (`--- @`) in view/win/parser modules: `parser.lua`, `win.lua`, `view.lua`

```lua
---@param bufnr integer
---@param name string
---@return string?

--- @class gotest.Win
--- @field opts gotest.win.Config
--- @field _buf number
```

Optional fields use `?` suffix: `---@field cwd? string`.

### Error Handling
- **Preconditions**: `assert(value, "message")` for argument validation:
  ```lua
  assert(bufnr and bufnr >= 0, "bufnr must be a valid buffer number")
  assert(lines, "Expected non-nil lines")
  ```
- **Graceful failures**: early return `nil` — do not propagate errors across module boundaries
- **Recoverable errors**: `pcall` for operations that may fail (e.g. JSON decoding):
  ```lua
  local ok, decoded = pcall(vim.fn.json_decode, line)
  if not ok then return nil end
  ```
- **User-facing messages**: always via `Notify.warn()` / `Notify.error()` / `Notify.info()`, never
  raw `vim.notify` or `print`
- Do not use `error()` at module boundaries

### Async Pattern
User commands are wrapped in a timer + coroutine pattern defined in `init.lua`:
```lua
function M._run_user_command(fn)
  local timer = vim.uv.new_timer()
  assert(timer, "Failed to create uv timer")
  return timer:start(0, 0, function()
    vim.schedule(function()
      local co = coroutine.create(function()
        fn()
        timer:close()
      end)
      coroutine.resume(co)
    end)
  end)
end
```
CLI jobs use `vim.fn.jobstart()` with `vim.schedule()` in callbacks.

---

## Testing

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)'s busted framework.

### File Naming
`<module>_spec.lua` — e.g. `cli_spec.lua`, `parser_spec.lua`, `ts_spec.lua`

### Test Structure
```lua
local ModuleName = require("gotest.module_name")
local utils = require("tests.gotest.utils")

utils.setup_test()

describe("module", function()
  it("should do something", function()
    -- ...
  end)
end)
```

### Assertions
```lua
assert.are.same(expected, actual)       -- deep table equality
assert.is.equals(expected, actual)      -- value equality
assert.is.Nil(actual)                   -- nil check
assert.is.not_nil(actual)               -- non-nil check
assert.is.error(function() ... end)     -- expects a thrown error
assert.is.truthy(value)
```

### Fixtures
Loaded via `tests/gotest/utils.lua` helpers. Fixture path root: `./tests/gotest/fixtures/`.
```lua
utils.load_fixture("/gotest_parse/output.json")       -- returns string[]
utils.load_buf_fixture("/ts/sum_test.go", "go")       -- returns bufnr, sets as current buf
```

### Notes
- Tests run **sequentially** (`sequential = true`) — parallel child processes deadlock on
  `vim.pack.add`'s lockfile.
- The Go Tree-sitter parser must be installed before running `ts_spec.lua`. In CI this is done
  explicitly before `make test`. Locally it is installed on first run by `nvim-treesitter`.
- `scripts/minimal_init.lua` uses `vim.pack.add` (Neovim 0.11+) — requires Neovim ≥ 0.11.
- `utils.setup_test()` must remain a minimal no-op: do not add `update()`, `ensure_installed()`,
  or `auto_install` calls — they hang in headless mode.
