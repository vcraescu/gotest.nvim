# gotest

## Install

### Lazy

```
return {
  "vcraescu/gotest.nvim",
  cmd = "GoTestNearest",
  config = true,
  opts = {
    output = {
        focus = {
            fail = true, -- focus test results on fail
            success = false, -- focus test results on success
        },
    },
    timeout = 30000, -- test run timeout
    diagnostics = {
        enabled = true, -- show diagnostics
    },
  }
}
```
