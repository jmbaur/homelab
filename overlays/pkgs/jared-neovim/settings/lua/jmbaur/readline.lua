-- bring in desired functionality from vim-rsi
vim.keymap.set('c', '<C-a>', '<Home>')
vim.keymap.set('c', '<C-x><C-a>', '<C-a>')
vim.keymap.set('c', '<C-e>', '<End>')
-- vim.keymap.set("c", "<C-k>", TODO)
vim.keymap.set('c', '<C-b>', '<Left>')
vim.keymap.set(
  'c',
  '<C-f>',
  function() return vim.fn.getcmdpos() > #vim.fn.getcmdline() and vim.opt.cedit:get() or '<Right>' end,
  { expr = true }
)
vim.keymap.set('c', '<C-d>', function()
  if vim.fn.getcmdpos() > #vim.fn.getcmdline() then
    return '<C-d>'
  else
    return '<Del>'
  end
end, { expr = true })
