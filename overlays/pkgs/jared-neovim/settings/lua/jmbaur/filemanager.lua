require('oil').setup()

vim.keymap.set('n', '-', vim.cmd.Oil, { desc = 'Open parent directory' })
