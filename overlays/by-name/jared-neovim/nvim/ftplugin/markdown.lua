vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.showbreak = "> "
vim.opt_local.conceallevel = 2
vim.opt_local.colorcolumn = ""

vim.keymap.set("n", "j", "gj", { buffer = true })
vim.keymap.set("n", "<Down>", "g<Down>", { buffer = true })
vim.keymap.set("n", "k", "gk", { buffer = true })
vim.keymap.set("n", "<Up>", "g<Up>", { buffer = true })
