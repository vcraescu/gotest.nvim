# gotest

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

## Install

### Lazy

```lua
return {
  "vcraescu/gotest.nvim",
  cmd = "GoTestNearest",
  opts = {}
}
```

## Default config
```lua
{
  output = {
     focus = {
       fail = true, -- focus test results on fail
       success = false, -- focus test results on success
     },
     height = 15, -- height of the quickfix pane
     show = {
       fail = true,
       success = true,
     },
  },
  timeout = 30, -- test run timeout in seconds
  disable_test_cache = false, -- disable go test cache
  diagnostics = {
     enabled = true, -- show diagnostics
  },
}
```

## Commands

```
:GoTestNearest
```
