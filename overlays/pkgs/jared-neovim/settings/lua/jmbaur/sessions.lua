local sessions = require('mini.sessions')

sessions.setup({})

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('AutoSessions', {}),
  nested = true,
  once = true,
  desc = 'Autoread latest session',
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.filereadable(vim.fn.getcwd() .. '/Session.vim') == 1 then sessions.read() end
  end,
})
