vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.showbreak = '+++ '
vim.keymap.set({ 'n', 'v' }, 'j', 'gj', { buffer = true })
vim.keymap.set({ 'n', 'v' }, '<Down>', 'g<Down>', { buffer = true })
vim.keymap.set({ 'n', 'v' }, 'k', 'gk', { buffer = true })
vim.keymap.set({ 'n', 'v' }, '<Up>', 'g<Up>', { buffer = true })
