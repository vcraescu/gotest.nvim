# gotest.nvim

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.11+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Tests](https://github.com/vcraescu/gotest.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/vcraescu/gotest.nvim/actions/workflows/ci.yml)

A Neovim plugin for running Go tests from within the editor. Uses Tree-sitter to intelligently
detect the test at the cursor, runs `go test -v -json` asynchronously, and renders results in an
interactive tree view with diagnostics.

## Features

- Detects the test under the cursor using Tree-sitter:
  - Table-driven subtests (`{ name: "foo", ... }` struct entries)
  - `t.Run("name", ...)` subtests
  - The enclosing `Test*` function
  - All tests in the file when the cursor is outside any test function
- Runs `go test -v -json` asynchronously — editor stays responsive
- Interactive collapsible tree view of test results
- Failed tests sorted to the top
- `vim.diagnostic` markers on failed test function definitions
- Reusable split window — reused across runs, not recreated
- Winbar shows the exact `go test` command that was run
- `:GoTestRetry` to re-run the last test without moving the cursor

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
```

## Commands

| Command | Description |
|---|---|
| `:GoTestNearest` | Run the Go test nearest to the cursor |
| `:GoTestRetry` | Re-run the last executed test command |

## Configuration

Call `require("gotest").setup(opts)` with any overrides. All keys are optional.

```lua
require("gotest").setup({
  view = {
    type = "tree",          -- "tree" | "raw"
    height = 15,            -- height of the output split in lines
    focus_on_fail = true,   -- focus the output pane on failure
    focus_on_success = false,
    show_on_fail = true,    -- open the output pane on failure
    show_on_success = true,
    tree = {
      indent = "  ",        -- indentation per level
      icons = {
        closed = " ",      -- collapsed node icon (Nerd Font)
        opened = " ",      -- expanded node icon (Nerd Font)
      },
    },
  },
  timeout = 30,             -- go test -timeout value in seconds
  disable_test_cache = false, -- pass -count=1 to disable go test cache
  diagnostics = {
    enabled = true,         -- show vim.diagnostic markers on failed tests
  },
})
```

### Options

| Option | Default | Description |
|---|---|---|
| `view.type` | `"tree"` | Output mode: `"tree"` for interactive tree, `"raw"` for plain output |
| `view.height` | `15` | Height of the output split pane in lines |
| `view.focus_on_fail` | `true` | Move cursor to the output pane when tests fail |
| `view.focus_on_success` | `false` | Move cursor to the output pane when tests pass |
| `view.show_on_fail` | `true` | Open the output pane when tests fail |
| `view.show_on_success` | `true` | Open the output pane when tests pass |
| `view.tree.indent` | `"  "` | Indentation string per tree level |
| `view.tree.icons.closed` | `" "` | Icon for a collapsed tree node |
| `view.tree.icons.opened` | `" "` | Icon for an expanded tree node |
| `timeout` | `30` | Test timeout passed to `go test -timeout` |
| `disable_test_cache` | `false` | When `true`, always passes `-count=1` to bypass the Go test cache |
| `diagnostics.enabled` | `true` | Place `vim.diagnostic` warning markers on failed `Test*` function lines |

## Tree View

The default `view.type = "tree"` renders a collapsible tree of test results.

**Highlights:**

| Result | Highlight group |
|---|---|
| Failed | `DiagnosticError` |
| Passed | `DiagnosticOk` |
| Skipped | `DiagnosticWarn` |
| Ignored | `DiagnosticUnnecessary` |

**Keymaps inside the output window:**

| Key | Action |
|---|---|
| `<CR>` | Toggle expand/collapse node |
| `o` | Toggle expand/collapse node |
| `q` | Close the output window |

## How Test Detection Works

`:GoTestNearest` walks the Tree-sitter AST from the cursor position and resolves, in order:

1. **Table-driven subtest** — cursor inside a `{ name: "my case", ... }` struct literal entry
2. **`t.Run` subtest** — cursor inside a `t.Run("my case", func(t *testing.T) { ... })` block
3. **Enclosing `Test*` function** — cursor anywhere inside a `func TestFoo(t *testing.T)` body
4. **All tests in the file** — cursor is outside any test function

The resulting `-run` flag uses `\Q...\E` POSIX quoting for exact name matching, with subtests
separated by `/`.

## Diagnostics

When `diagnostics.enabled = true`, a `DiagnosticWarn` marker with the message `FAILED` is placed
at the line of each failed `func Test*` definition. Diagnostics are cleared before every new run.
