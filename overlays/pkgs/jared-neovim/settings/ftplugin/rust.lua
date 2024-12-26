vim.g.cargo_makeprg_params = 'build'

local group = vim.api.nvim_create_augroup('RustCompiler', {})
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  pattern = { '*.rs' },
  group = group,
  desc = 'Set Rust compiler',
  once = true,
  callback = function()
    if vim.fn.executable('cargo') == 1 then
      vim.cmd.compiler('cargo')
    else
      vim.cmd.compiler('rustc')
    end
  end,
})
