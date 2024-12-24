local telescope = require('telescope')
local telescope_builtin = require('telescope.builtin')

telescope.load_extension('ui-select')
telescope.load_extension('zf-native')

vim.keymap.set('n', '<leader>?', telescope_builtin.help_tags, { desc = 'Find help tags' })
vim.keymap.set('n', '<leader>_', telescope_builtin.registers, { desc = 'Find registers' })
vim.keymap.set('n', '<leader>b', telescope_builtin.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>c', telescope_builtin.resume, { desc = 'Resume picker' })
vim.keymap.set('n', '<leader>f', telescope_builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>g', telescope_builtin.live_grep, { desc = 'Find regexp pattern' })
vim.keymap.set('n', '<leader>h', telescope_builtin.command_history, { desc = 'Find Ex-mode history' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspAttachLauncherKeybinds', {}),
  callback = function(event)
    vim.keymap.set(
      'n',
      '<leader>w',
      function() telescope_builtin.diagnostics({ bufnr = nil }) end,
      { desc = 'Find workspace diagnostics' }
    )
    vim.keymap.set(
      'n',
      '<leader>d',
      function() telescope_builtin.diagnostics({ bufnr = event.buf }) end,
      { desc = 'Find document diagnostics' }
    )
    vim.keymap.set(
      'n',
      '<leader>i',
      telescope_builtin.lsp_implementations,
      { buffer = event.buf, desc = 'LSP implementations' }
    )
    vim.keymap.set('n', '<leader>r', telescope_builtin.lsp_references, { buffer = event.buf, desc = 'LSP references' })
  end,
})
