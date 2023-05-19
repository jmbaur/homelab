vim.g.mapleader = " "

if #vim.api.nvim_list_uis() > 0 then
	require("compile")
	require("filemanager")
	require("gosee").setup()
	require("launcher")
	require("lsp")
	require("mini.tabline").setup({ show_icons = false, set_vim_settings = false })
	require("mini.trailspace").setup({})
	require("run").setup()
	require("sitter")
	require("smartyank").setup({ highlight = { enabled = false }, osc52 = { silent = true } })
	require("snippet")
	require("statusline")
	require("terminal")

	vim.cmd.colorscheme("jared")
	vim.opt.belloff = "all"
	vim.opt.colorcolumn = "80"
	vim.opt.cursorline = true
	vim.opt.laststatus = 2
	vim.opt.number = true
	vim.opt.relativenumber = true
end

if vim.g.neovide then
	require("neovide")
end

require("mini.bracketed").setup({})
require("mini.comment").setup({
	ignore_blank_line = true,
	start_of_line = true,
})
require("nvim-surround").setup()

vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.wrap = false
