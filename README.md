# gotest

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