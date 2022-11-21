vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4

-- for lambdas
MiniPairs.map_buf(0, "i", "|", { action = "closeopen", pair = "||" })
