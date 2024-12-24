vim.opt.clipboard = 'unnamedplus'

-- Not all terminals support osc52 paste, and there are security concerns for enabling it
local function paste() return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') } end

-- if not on a tty, setup the clipboard to use osc52
if vim.env.TERM ~= 'linux' then
  local osc52 = require('vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = osc52.copy('+'),
      ['*'] = osc52.copy('*'),
    },
    paste = {
      ['+'] = paste,
      ['*'] = paste,
    },
  }
end
