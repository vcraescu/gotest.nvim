# gotest.nvim

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.11+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Tests](https://github.com/vcraescu/gotest.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/vcraescu/gotest.nvim/actions/workflows/ci.yml)

A Neovim plugin for running Go tests from within the editor. Uses Tree-sitter to intelligently detect the test at the
cursor, runs `go test -v -json` asynchronously, and renders results in a split or floating window with diagnostics.

## Features

- Detects the test under the cursor using Tree-sitter:
  - Table-driven subtests (`{ name: "foo", ... }` struct entries)
  - `t.Run("name", ...)` subtests
  - The enclosing `Test*` function
  - All tests in the file when the cursor is outside any test function
- Runs `go test -v -json` asynchronously — editor stays responsive
- `vim.diagnostic` markers on failed test function definitions
- Reuse the split or floating window across test runs
- Winbar shows the exact `go test` command that was run
- `:GoTestRetry` to re-run the last test without moving the cursor
- `:GoTestToggle` to show or hide the last test output

## Requirements

- Neovim ≥ 0.11
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) with the Go parser installed
- `go` available on `$PATH`

## Installation

### lazy.nvim

```lua
{
  "vcraescu/gotest.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = { "GoTestNearest", "GoTestRetry" },
  opts = {},
}
```

### Manual keymaps (recommended)

The plugin registers no keymaps globally. Map the commands yourself:

```lua
vim.keymap.set("n", "<leader>tt", "<cmd>GoTestNearest<CR>", { desc = "Go: run nearest test" })
vim.keymap.set("n", "<leader>tr", "<cmd>GoTestRetry<CR>",   { desc = "Go: retry last test" })
vim.keymap.set("n", "<leader>tv", "<cmd>GoTestToggle<CR>",  { desc = "Go: toggle last test output" })
```

## Commands

| Command          | Description                                  |
| ---------------- | -------------------------------------------- |
| `:GoTestNearest` | Run the Go test nearest to the cursor        |
| `:GoTestRetry`   | Re-run the last executed test command        |
| `:GoTestToggle`  | Show or hide the last test run output window |

## Configuration

Call `require("gotest").setup(opts)` with any overrides. All keys are optional.

```lua
require("gotest").setup({
  view = {
    type = "split",        -- Use "split" or "float".
    height = 15,            -- Set the split height in rows.
    float = {
      width = 0.8,          -- Set the float width.
      height = 0.8,         -- Set the float height.
      border = "rounded",   -- Optional. Overrides the 'winborder' option.
    },
    focus_on_fail = true,   -- focus the output pane on failure
    focus_on_success = false,
    show_on_fail = true,    -- open the output pane on failure
    show_on_success = true,
  },
  timeout = 30,             -- go test -timeout value in seconds
  disable_test_cache = false, -- pass -count=1 to disable go test cache
  diagnostics = {
    enabled = true,         -- show vim.diagnostic markers on failed tests
  },
})
```

### Options

| Option                  | Default       | Description                                                                                                                |
| ----------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `view.type`             | `"split"`     | Window type: `"split"` or `"float"`                                                                                        |
| `view.height`           | `15`          | Split height in rows                                                                                                       |
| `view.float.width`      | `0.8`         | Float width as a screen fraction or column count                                                                           |
| `view.float.height`     | `0.8`         | Float height as a screen fraction or row count                                                                             |
| `view.float.border`     | `'winborder'` | Float border. Defaults to the 'winborder' option. Accepts any `nvim_open_win` border value or a table of border characters |
| `view.focus_on_fail`    | `true`        | Move cursor to the output pane when tests fail                                                                             |
| `view.focus_on_success` | `false`       | Move cursor to the output pane when tests pass                                                                             |
| `view.show_on_fail`     | `true`        | Open the output pane when tests fail                                                                                       |
| `view.show_on_success`  | `true`        | Open the output pane when tests pass                                                                                       |
| `timeout`               | `30`          | Test timeout passed to `go test -timeout`                                                                                  |
| `disable_test_cache`    | `false`       | When `true`, always passes `-count=1` to bypass the Go test cache                                                          |
| `diagnostics.enabled`   | `true`        | Place `vim.diagnostic` warning markers on failed `Test*` function lines                                                    |

### Floating window

Set `view.type` to `"float"` to open a centered floating window:

```lua
require("gotest").setup({
  view = {
    type = "float",
    float = {
      width = 0.8,
      height = 0.8,
      border = "rounded", -- Optional. Overrides the 'winborder' option.
    },
  },
})
```

The default float width and height are `0.8`. Each value must be a positive number. Values below `1` specify a fraction
of the visible Neovim screen. For example, `0.8` means 80%. The available height excludes the command area. Values of
`1` or more specify columns for width and rows for height. For example, `float = { width = 100, height = 30 }` sets a
width of 100 columns and a height of 30 rows. You can use a fraction for one dimension and a row or column count for the
other dimension. The plugin rounds sizes down to whole cells. The plugin limits each size to the available screen space,
with a minimum of one cell. A one-row window does not show the winbar. `view.height` applies only to splits.

The float opens focused. By default, the border comes from the `'winborder'` option. Set `view.float.border` to override
it. You can use any `nvim_open_win` border value, for example `"single"`, `"double"`, `"solid"`, `"shadow"`, or
`"none"`. You can also set a table of border characters.

Press `q` to close the output window. The `q` key runs the same function as `:GoTestToggle`. This key works in splits
and floats. The key is buffer-local, so it does not override your global mappings. Closing the window returns focus to
the previous window. Use `:GoTestToggle` to open the window again later. If no test ran yet, the command shows a warning
message.

## How Test Detection Works

`:GoTestNearest` walks the Tree-sitter AST from the cursor position and resolves, in order:

1. **Table-driven subtest** — cursor inside a `{ name: "my case", ... }` struct literal entry
2. **`t.Run` subtest** — cursor inside a `t.Run("my case", func(t *testing.T) { ... })` block
3. **Enclosing `Test*` function** — cursor anywhere inside a `func TestFoo(t *testing.T)` body
4. **All tests in the file** — cursor is outside any test function

The resulting `-run` flag uses `\Q...\E` POSIX quoting for exact name matching, with subtests separated by `/`.

## Diagnostics

When `diagnostics.enabled = true`, a `DiagnosticWarn` marker with the message `FAILED` is placed at the line of each
failed `func Test*` definition. Diagnostics are cleared before every new run.
